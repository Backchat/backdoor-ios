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
#import "YTContactHelper.h"
#import "YTViewHelper.h"

@implementation YTApiHelper

+ (void)setup
{
    [YTAppDelegate current].autoSyncLock = [NSLock new];
    [YTApiHelper resetUserInfo];
    [YTAppDelegate current].deliveredMessages = [NSMutableDictionary new];
}

+ (void)resetUserInfo
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    NSString *deviceToken = delegate.userInfo ? delegate.userInfo[@"device_token"] : @"";
    delegate.sentInfo = [NSMutableDictionary new];
    delegate.userInfo = [NSMutableDictionary new];
    delegate.userInfo[@"device_token"] = deviceToken;
    delegate.userInfo[@"fb_data"] = [NSMutableDictionary new];
    delegate.userInfo[@"gpp_data"] = [NSMutableDictionary new];
    delegate.userInfo[@"settings"] = [NSMutableDictionary new];
}

+ (NSDictionary*)userParams
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSMutableDictionary *userInfo = delegate.userInfo;
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSData *data;
    if (!userInfo[@"access_token"]) {
        return nil;
    }
    result[@"access_token"] = userInfo[@"access_token"];
    result[@"provider"] = userInfo[@"provider"];
    //if (userInfo[@"fb_data"] && ![userInfo[@"fb_data"] isEqual:sentInfo[@"fb_data"]]) {
    data = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithDictionary:userInfo[@"fb_data"]] options:NSJSONWritingPrettyPrinted error:nil];
    result[@"fb_data"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    //}
    //if (userInfo[@"gpp_data"] && ![userInfo[@"gpp_data"] isEqual:sentInfo[@"gpp_data"]]) {
    data = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithDictionary:userInfo[@"gpp_data"]] options:NSJSONWritingPrettyPrinted error:nil];
    result[@"gpp_data"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //}
    

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
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [YTApiHelper toggleNetworkActivityIndicatorVisible:NO];
            
            if(![JSON[@"status"] isEqualToString:@"ok"]) {
                if (failure != nil) {
                    failure(JSON);
                }
                return;
            }
            
            if (success != nil) {
                success(JSON[@"response"]);
            } else {
                [YTViewHelper refreshViews];
            }
            
        }];
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [YTApiHelper toggleNetworkActivityIndicatorVisible:NO];

            if (response.statusCode == 503) {
                [YTApiHelper showMaintenanceModeAlert];
            } else {
                [YTApiHelper showNetworkErrorAlert];
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

+ (void)login:(void(^)(id JSON))success
{
    NSDictionary* params = [self userParams];
    NSString* device_token= [params valueForKey:@"device_token"];
    if(device_token == nil || device_token.length == 0)
        return;
        //this will occur when login is caleld as part of opening FB session, which occurs
        //before getting the device_token from APN.
        //this flow could only happen when you are not logged in yet, because when you log in,
        //we have a valid access_token we store indefinitely.
        //ultimately, login will be called again when the uesr hits a login button.
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Logging in", nil)
                                                 path:@"/login"
                                               method:@"POST" params:params
                                              success:^(id JSON) {
                                                  //we must have successfully logged in = we must be ok with server
                                                  [YTApiHelper hideNetworkErrorAlert];
                                                  [self getFriends];
                                                  if(success) {
                                                      success(JSON);
                                                  }
                                              }
                                              failure:nil];

}

+ (void)getUserInfo:(void(^)(id JSON))success
{
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


+ (void)syncGabs
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    if ([delegate.autoSyncLock tryLock] == NO) {
        return;
    }
          
    [YTApiHelper sendJSONRequestToPath:@"/gabs" method:@"GET" params:nil
                               success:^(id JSON) {
                                   id gabs = JSON[@"gabs"];
                                   for(id gab in gabs) {
                                       [YTModelHelper createOrUpdateGab:gab];
                                   }
                                   [delegate.autoSyncLock unlock];
                                   [YTViewHelper refreshViews];
                                   [YTViewHelper endRefreshing];
                               }
     
                               failure:^(id JSON) {
                                   [delegate.autoSyncLock unlock];
                                   [YTViewHelper endRefreshing];
                               }];
}

+ (void)syncGabWithId:(NSNumber *)gab_id popup:(BOOL)popup
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    if ([delegate.autoSyncLock tryLock] == NO) {
        return;
    }
    
    [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@", gab_id]
                                method:@"GET" params:@{@"extended":@true}
                               success:^(id JSON) {
                                   [YTModelHelper createOrUpdateGab:JSON[@"gab"]];

                                   [delegate.autoSyncLock unlock];
                                   [YTViewHelper refreshViews];
                                   [YTViewHelper endRefreshing];
                                   
                                   if(popup) {
                                       double delayInSeconds = 0.5;
                                       dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                       dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                           [YTViewHelper showGabWithId:gab_id];
                                       });
                                   }
                               }
     
                               failure:^(id JSON) {
                                   [delegate.autoSyncLock unlock];
                                   [YTViewHelper endRefreshing];
                               }];
}

+ (void)deleteGab:(NSNumber*)gabId success:(void(^)(id JSON))success
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [YTModelHelper clearGab:gabId];
        [YTViewHelper refreshViews];

        if(gabId.integerValue >= 0) {
            [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@", gabId]
                                        method:@"DELETE" params:nil success:success failure:nil];
            
            [Flurry logEvent:@"Deleted_Thread"];
            [[Mixpanel sharedInstance] track:@"Deleted Thread"];
        }
    }];

}

+ (void)tagGab:(NSNumber*)gabId tag:(NSString*)tag success:(void(^)(id JSON))success
{
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Updating thread", nil)
                                                 path:[NSString stringWithFormat:@"/gabs/%@", gabId]
                                               method:@"POST"
                                               params:@{@"related_user_name": tag}
                                              success:success
                                              failure:nil];
    [Flurry logEvent:@"Tagged_Thread"];
    [[Mixpanel sharedInstance] track:@"Tagged Thread"];
}

+ (void)requestClue:(NSNumber*)gabId number:(NSNumber*)number success:(void(^)(id JSON))success;
{
    [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@/clues/request/%@", gabId, number]
                                method:@"POST"
                                params:nil
                               success:success failure:nil];
    
    [Flurry logEvent:@"Requested_Clue"];
    [[Mixpanel sharedInstance] track:@"Requested Clue"];
}

+ (void)buyCluesWithReceipt:(NSString *)receipt success:(void(^)(id JSON))success
{
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
        NSInteger total = [YTModelHelper userAvailableClues];
        
        if (count == 0) {
            return;
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:
                              [NSString stringWithFormat:NSLocalizedString(@"You received %1$d free clues! Now you have %2$d available clues to use in all incoming threads", nil), count, total] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        
    } failure:nil];
}

+ (void)getFeaturedUsers
{
    if ([[[NSLocale currentLocale] localeIdentifier] isEqualToString:@"en_US"] && !CONFIG_DEBUG_FEATURED) {
        [YTAppDelegate current].featuredUsers = @[];
        return;
    }
    
    [YTApiHelper sendJSONRequestToPath:@"/featured-users" method:@"GET" params:nil success:^(id JSON) {
        [YTAppDelegate current].featuredUsers = JSON[@"users"];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [YTViewHelper refreshViews];
        }];
        
    } failure:nil];
}

+ (void)getFriends
{
    [YTApiHelper sendJSONRequestToPath:@"/friends" method:@"GET" params:nil success:^(id JSON) {
        
        [[YTContactHelper sharedInstance] loadFriends:JSON[@"friends"]];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [YTViewHelper refreshViews];
        }];
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

@end
