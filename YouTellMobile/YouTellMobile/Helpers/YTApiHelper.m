//
//  YTApiHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

//LINREVIEW deal with failure:nil situations?

#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import <AFNetworking/AFJSONRequestOperation.h>
#import <AFNetworking/AFHTTPClient.h>
#import <Facebook-iOS-SDK/FacebookSDK/Facebook.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <Flurry.h>
#import <Mixpanel.h>

#import "YTConfig.h"
#import "YTAppDelegate.h"
#import "YTHelper.h"
#import "YTApiHelper.h"
#import "YTModelHelper.h"
#import "YTViewHelper.h"
#import "YTFriends.h"
#import "YTViewHelper.h"
#import "YTTourViewController.h"
#import "YTGPPHelper.h"
#import "YTFBHelper.h"
#import "YTContact.h"
#import "YTSocialHelper.h"
#import "YTGabs.h"

@implementation YTApiHelper

+ (void)setup
{
    [YTApiHelper resetUserInfo];
    [YTAppDelegate current].deliveredMessages = [NSMutableDictionary new];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:YTDeviceTokenAcquired
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      NSLog(@"device token -> try login again");
                                                      if([YTAppDelegate current].userInfo[@"access_token"]) {
                                                          NSLog(@"has access_token-> trying again");
                                                          [YTApiHelper login];
                                                      }
                                                  }];
}

+ (void)resetUserInfo
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    NSString *deviceToken = delegate.userInfo ? delegate.userInfo[@"device_token"] : @"";
    NSNumber* launch_on_active_token = delegate.userInfo ? delegate.userInfo[@"launch_on_active_token"] : nil;
    delegate.sentInfo = [NSMutableDictionary new];
    delegate.userInfo = [NSMutableDictionary new];
    delegate.userInfo[@"device_token"] = deviceToken;
    delegate.userInfo[@"fb_data"] = [NSMutableDictionary new];
    delegate.userInfo[@"gpp_data"] = [NSMutableDictionary new];
    delegate.userInfo[@"settings"] = [NSMutableDictionary new];
    if(launch_on_active_token)
        delegate.userInfo[@"launch_on_active_token"] = launch_on_active_token;
}

+ (NSDictionary*)userParams
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSMutableDictionary *userInfo = delegate.userInfo;
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSData *data;
        
    result[@"access_token"] = userInfo[@"access_token"];
    result[@"provider"] = userInfo[@"provider"];
    
    data = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithDictionary:userInfo[@"fb_data"]] options:NSJSONWritingPrettyPrinted error:nil];
    result[@"fb_data"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    data = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithDictionary:userInfo[@"gpp_data"]] options:NSJSONWritingPrettyPrinted error:nil];
    result[@"gpp_data"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    result[@"device_token"] = userInfo[@"device_token"];
    return result;
}

+ (NSURL*)baseUrl
{
    return [NSURL URLWithString:CONFIG_URL];
}

+ (void)toggleNetworkActivityIndicatorVisible:(BOOL)visible
{
    static int count = 0;
    @synchronized(self) {
        visible ? count++ : count--;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(count > 0)];
    }
}

+ (void) sendJSONRequestToPath:(NSString*)path method:(NSString*)method params:(NSDictionary*)params success:(void(^)(id JSON))success failure:(void(^)(id JSON))failure
{
    
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[YTApiHelper baseUrl]];
    
    NSMutableDictionary *myParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    if([myParams valueForKey:@"access_token"] == nil) {
        NSString* access_token = [YTAppDelegate current].userInfo[@"access_token"];
        [myParams setValue:access_token forKey:@"access_token"];
    }
    
    NSMutableURLRequest *request = [client requestWithMethod:method path:path parameters:myParams];
        
    [request setTimeoutInterval:CONFIG_TIMEOUT];
    AFJSONRequestOperation *operation =
    [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                        [YTApiHelper toggleNetworkActivityIndicatorVisible:NO];
#if CONFIG_TEST_SLOW_API
                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                                                                       ^{
                                                                           [NSThread sleepForTimeInterval:2.0];
                                                                           [[NSOperationQueue mainQueue] addOperationWithBlock:^{
#endif
                                                                               if(![JSON[@"status"] isEqualToString:@"ok"]) {
                                                                                   if (failure != nil) {
                                                                                       failure(JSON);
                                                                                   }
                                                                                   return;
                                                                               }
                                                                               
                                                                               if (success != nil) {
                                                                                   success(JSON[@"response"]);
                                                                               }
#if CONFIG_TEST_SLOW_API
                                                                               
                                                                           }];
                                                                       });
#endif
                                                    }
                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            [YTApiHelper toggleNetworkActivityIndicatorVisible:NO];
                                                            
                                                            if (response.statusCode == 503) {
                                                                [YTApiHelper showMaintenanceModeAlert];
                                                            } else {
                                                                //[YTApiHelper showNetworkErrorAlert]; TODO...
                                                                NSLog(@"%@", [error debugDescription]);
                                                            }
                                                            
                                                            if (failure != nil) {
                                                                failure(JSON);
                                                            }
                                                        }];
                                                    }];
    
    [YTApiHelper toggleNetworkActivityIndicatorVisible:YES];
    
    [operation start];
}

+ (void) sendJSONRequestWithBlockingUIMessage:(NSString*)message
                                         path:(NSString*)path
                                       method:(NSString*)method
                                       params:(NSDictionary*)params
                                      success:(void(^)(id JSON))success
                                      failure:(void(^)(id JSON))failure
{
    [SVProgressHUD showWithStatus:message maskType:SVProgressHUDMaskTypeClear];
    
    [YTApiHelper sendJSONRequestToPath:path method:method params:params success:^(id JSON) {
        [SVProgressHUD dismiss];
        if(success) {
            success(JSON);
        }
        
    } failure:^(id JSON) {
        [SVProgressHUD dismiss];
        if(failure) {
            failure(JSON);
        }
    }];
    
}

+ (void)sendFeedback:(NSString*)content rating:(NSNumber*)rating success:(void(^)(id JSON))success
{
    NSDictionary *params = @{
                             @"rating": rating,
                             @"content": content
                             };
    
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Delivering feedback", nil)
                                                 path:@"/feedbacks"
                                               method:@"POST"
                                               params:params
                                              success:success
                                              failure:nil];
    [Flurry logEvent:@"Sent_Feedback"];
    [[Mixpanel sharedInstance] track:@"Sent Feedback" properties:@{@"rating": rating}];
}

+ (void)postLogin
{
    //set the access_token locally so we know we're good:
    NSString* access_token = [YTAppDelegate current].userInfo[@"access_token"];
    
    [YTModelHelper setSettingsForKey:@"logged_in_access_token" value:access_token];
    [YTModelHelper setSettingsForKey:@"logged_in_provider" value:[YTAppDelegate current].userInfo[@"provider"]];
    
    [YTViewHelper hideLogin];

    NSNumber* launch_on_login = [YTAppDelegate current].userInfo[@"launch_on_active_token"];

    if(launch_on_login) {
        NSLog(@"launch on login: %@", launch_on_login);

        [YTViewHelper showGabWithGabId:launch_on_login];

        [[YTAppDelegate current].userInfo removeObjectForKey:@"launch_on_active_token"];
    }
}

//refactor these stupid static bools out soon
static bool loggedIn;
+ (bool)loggedIn
{
    return loggedIn;
}

+ (void)logout
{
    loggedIn = false;
    [YTModelHelper removeSettingsForKey:@"logged_in_acccess_token"];
    [YTModelHelper removeSettingsForKey:@"logged_in_provider"];
    
    //TODO better?
    [[YTAppDelegate current].storeHelper disable];
    [YTAppDelegate current].storeHelper = nil;
    
    [[Mixpanel sharedInstance] track:@"Signed Out"];
    
    [[YTSocialHelper sharedInstance] logoutProviders];
    
    [YTModelHelper changeStoreId:nil];
    
    [YTApiHelper resetUserInfo];
    
    [YTViewHelper showLoginWithButtons];
}

+ (bool)attemptCachedLogin
{
    NSString* local_access_token = [YTModelHelper settingsForKey:@"logged_in_access_token"];
    NSString* logged_in_provider = [YTModelHelper settingsForKey:@"logged_in_provider"];
    
    if(local_access_token && local_access_token.length > 0 &&
       logged_in_provider && logged_in_provider.length > 0)
    {
        [YTAppDelegate current].userInfo[@"access_token"] = local_access_token;
        loggedIn = true;
        /* we do, but we still need to reauth our social media. */
        [[YTSocialHelper sharedInstance] reauthProviders];
        [YTApiHelper postLogin];
        //TODO do full fireLogin once we get the fetchUserData to work right
        return true;
    }
    else
        return false;
}

+ (void)fireLoginSuccess
{
    [[NSNotificationCenter defaultCenter] postNotificationName:YTLoginSuccess object:nil];
}

/* Login can be called by two things:
 * device token acquired -> login
 * social provider:authed -> login
 */
+ (void)login
{
    if([YTApiHelper loggedIn]) {
        NSLog(@"already loggedin ");
        return;
    }
    
    if([YTApiHelper attemptCachedLogin]) {
        NSLog(@"logged in via cached access token");
        return;
    }    
    
    NSDictionary* params = [self userParams];
    NSString* device_token= [params valueForKey:@"device_token"];
    if(device_token == nil || device_token.length == 0) {
        //this might only occur if login is called so fast that didRegister... didn't get called yet
        //it will, at some point, get called since we call registerFor... in the main appdelegate.
        //we listen to the YTDeviceTokenAcquired so we will recall ourselves
        NSLog(@"login before devicetoken");
        return;
    }

    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Logging in", nil)
                                                 path:@"/login"
                                               method:@"POST" params:params
                                              success:^(id JSON) {
                                                  loggedIn = true;
                                                  //we must have successfully logged in = we must be ok with server
                                                  [YTApiHelper hideNetworkErrorAlert];
                                                  //are we a new user? then show the tour:
                                                  NSNumber* num = JSON[@"user"][@"new_user"];
                                                  //we got settings!
                                                  [YTAppDelegate current].userInfo[@"settings"] =
                                                  [NSMutableDictionary dictionaryWithDictionary:JSON[@"user"][@"settings"]];
                                                   
                                                  if(num)
                                                      [YTApiHelper setNewUser:((num.integerValue == 1) || CONFIG_DEBUG_TOUR)];
                                                  
                                                  [YTApiHelper fireLoginSuccess];
                                              }
                                              failure:nil];

}

static bool new_user = false;
+ (void)setNewUser:(bool)user
{
    new_user = user;
}

+ (bool)isNewUser
{
    return new_user;
}

//NOTE: currentyl unused we get info from login and go from there
+ (void)getUserInfo:(void(^)(id JSON))success
{
    return;
    
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Please wait...", nil)
                                                 path:@"/"
                                               method:@"GET" params:nil
                                              success:^(id JSON) {
                                                  [YTModelHelper setUserAvailableClues:JSON[@"available_clues"]];
                                                  if(success)
                                                      success(JSON);
                                              }
                                              failure:nil];
}

+ (void)updateUserInfo:(void(^)(id JSON))success
{
    NSDictionary* params = [self userParams]; //TODO better?
    
    [YTApiHelper sendJSONRequestToPath:@"/"
                                method:@"POST" params:params
                               success:success
                               failure:nil];
}

+ (void)sendAbuseReport:(NSString*)content success:(void(^)(id JSON))success
{
    NSDictionary *params = @{@"content": content};
    
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Delivering report", nil)
                                                 path:@"/report-abuse"
                                               method:@"POST" params:params
                                              success:success
                                              failure:nil];
    [Flurry logEvent:@"Sent_Abuse_Report"];
    [[Mixpanel sharedInstance] track:@"Sent Abuse Report"];
}

+ (void)getCluesForGab:(NSNumber*)gab_id success:(void(^)(id JSON))success
{
    [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@/clues/", gab_id]
                                method:@"GET"
                                params:@{@"available_clues": @true}
                               success:^(id JSON) {
                                   for (id clue in JSON[@"clues"])
                                       [YTModelHelper createOrUpdateClue:clue];
                                   
                                   if(JSON[@"available_clues"])
                                       [YTModelHelper setUserAvailableClues:JSON[@"available_clues"]];

                                   if(success)
                                       success(JSON);
                               }
                               failure:nil];
}

+ (void)requestClue:(NSNumber*)gabId number:(NSNumber*)number success:(void(^)(id JSON))success;
{
    [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@/clues/request/%@", gabId, number]
                                method:@"POST"
                                params:nil
                               success:^(id JSON) {
                                   [YTModelHelper createOrUpdateClue:JSON[@"clue"]];
                                   
                                   if(success)
                                       success(JSON);
                               }
                               failure:nil];
    
    [Flurry logEvent:@"Requested_Clue"];
    [[Mixpanel sharedInstance] track:@"Requested Clue"];
}

+ (void)buyCluesWithReceipt:(NSString *)receipt success:(void(^)(id JSON))success
{
    // Delay the request until user is properly signed in
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSString *accessToken = delegate.userInfo[@"access_token"];
    if (!accessToken) {
        double delayInSeconds = 1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [YTApiHelper buyCluesWithReceipt:receipt success:success];
        });
        return;     
    }

    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Verifying transaction", nil)
                                                 path:@"/buy-clues"
                                               method:@"POST"
                                               params:@{@"receipt": receipt}
                                              success:success
                                              failure:nil];
}

+ (void)getFreeCluesWithReason:(NSString *)reason
{
    [YTApiHelper sendJSONRequestToPath:@"/free-clues" method:@"POST" params:@{@"reason":reason} success:^(id JSON) {
        
        NSInteger count = [JSON[@"count"] integerValue];
        [YTModelHelper setUserAvailableClues:JSON[@"available_clues"]];
        [YTAppDelegate current].userInfo[@"settings"][@"has_shared"] = [NSNumber numberWithBool:true];

        NSInteger total = [YTModelHelper userAvailableClues];
        
        if (count == 0) {
            return;
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:
                              [NSString stringWithFormat:NSLocalizedString(@"You received %1$d free clues! Now you have %2$d available clues to use in all incoming threads", nil), count, total] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        
    } failure:nil];
}

+ (void)updateSettingsWithKey:(NSString*)key value:(id)value
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"value":value} options:0 error:&error];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [YTApiHelper sendJSONRequestToPath:@"/update-settings" method:@"POST" params:@{@"key":key,@"value":json} success:nil failure:nil];
}

+ (void)checkUpdates
{
    
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Checking for updates", nil)
                                                 path:@"/check-updates"
                                               method:@"POST" params:@{}
                                              success:^(id JSON) {
                                                  
                                                  NSString *my_version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
                                                  NSString *current_version = JSON[@"current_version"];
                                                  if ([my_version isEqualToString:current_version]) {
                                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Update not available", nil) message:NSLocalizedString(@"You are running the current version of Backdoor. Good job!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                                                      [alert show];
                                                      return;
                                                  }
                                                  NSString *urlS = [NSString stringWithFormat:@"http://itunes.apple.com/us/app/id%@?mt=8", CONFIG_APPLE_ID];
                                                  NSURL *url = [NSURL URLWithString:urlS];

                                                  [[UIApplication sharedApplication] openURL:url];
                                              } failure:nil];
}


+ (void)showNetworkErrorAlert
{
    NSString *title = NSLocalizedString(@"Network error", nil);
    NSString *message = NSLocalizedString(@"Unable to connect with Backdoor server. Please check your data connection", nil);
    [YTViewHelper showAlertWithTitle:title message:message];
};

+ (void)hideNetworkErrorAlert
{
    [YTViewHelper hideAlert];
}

+ (void)showMaintenanceModeAlert
{
    NSString *title = NSLocalizedString(@"Maintenance mode", nil);
    NSString *message = NSLocalizedString(@"Our server is currently undergoing a scheduled maintenance. Please try again later.", nil);
    [YTViewHelper showAlertWithTitle:title message:message];
}

+ (void)sendInviteText:(YTContact*)contact body:(NSString*)body success:(void(^)(id JSON))success
{
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Sending invite", nil)
                                                 path:@"/invites" method:@"POST"
                                               params:
     @{@"invite": @{@"body": body},
     @"contact": @{@"phone_number": contact.phone_number}}
                                              success:^(id JSON) {
                                                  if(success)
                                                      success(JSON);
                                              } failure:^(id JSON) {                                                  
                                                  
                                              }];
}

@end

NSString* const YTLoginSuccess = @"YTLoginSuccess";
