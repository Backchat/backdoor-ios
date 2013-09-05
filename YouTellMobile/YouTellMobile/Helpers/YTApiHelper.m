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
#import "YTContact.h"
#import "YTSocialHelper.h"
#import "YTLoginViewController.h"

@implementation YTApiHelper

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

+ (AFHTTPRequestOperation*)networkingOperationForSONRequestToPath:(NSString*)path
                                                           method:(NSString*)method
                                                           params:(NSDictionary*)params
                                                          success:(void(^)(id JSON))success
                                                          failure:(void(^)(id JSON))failure
{
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[YTApiHelper baseUrl]];
    
    NSMutableDictionary *myParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    if([myParams valueForKey:@"access_token"] == nil) {
        //TODO fix this to have separate auth / non-auth...
        if(!YTAppDelegate.current.currentUser)
        {
            NSLog(@"JSON logged out");
            return nil;
        }
        
        [myParams setValue:YTAppDelegate.current.currentUser.accessToken forKey:@"access_token"];
    }
    
    NSMutableURLRequest *request = [client requestWithMethod:method path:path parameters:myParams];
    
    [request setTimeoutInterval:CONFIG_TIMEOUT];
    AFJSONRequestOperation *operation =
    [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
#if CONFIG_TEST_SLOW_API
                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                                                                       ^{
                                                                           [NSThread sleepForTimeInterval:3.0];
                                                                           [[NSOperationQueue mainQueue] addOperationWithBlock:^{
#endif
                                                                               [YTApiHelper toggleNetworkActivityIndicatorVisible:NO];
                                                                               
                                                                               //TODO fix this
                                                                               bool loginRequest = [request.URL.path isEqualToString:@"/login"];
                                                                               if(!loginRequest && YTAppDelegate.current.currentUser == nil) {
                                                                                   [YTApiHelper toggleNetworkActivityIndicatorVisible:NO];
                                                                                   NSLog(@"JSON response logged out");
                                                                                   return;
                                                                               }
                                                                               
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
                                                            } else if(response.statusCode == 401) {
                                                                [YTViewHelper invalidSessionLogout];
                                                                
                                                                return;
                                                            }
                                                            else {
                                                                //[YTApiHelper showNetworkErrorAlert]; TODO...
                                                                NSLog(@"%@", [error debugDescription]);
                                                            }
                                                            
                                                            if (failure != nil) {
                                                                failure(JSON);
                                                            }
                                                        }];
                                                    }];

    return operation;
}

+ (void) sendJSONRequestToPath:(NSString*)path method:(NSString*)method params:(NSDictionary*)params success:(void(^)(id JSON))success failure:(void(^)(id JSON))failure
{   
    
    [YTApiHelper toggleNetworkActivityIndicatorVisible:YES];
    AFHTTPRequestOperation* operation = [YTApiHelper networkingOperationForSONRequestToPath:path method:method params:params success:success failure:failure];
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
    if (!YTAppDelegate.current.currentUser) {
        //TODO fix this with a notification...scared to touch bceause of IAP
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
        YTAppDelegate.current.currentUser.userHasShared = @true;

        NSInteger total = [YTModelHelper userAvailableClues];
        
        if (count == 0) {
            return;
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:
                              [NSString stringWithFormat:NSLocalizedString(@"You received %1$d free clues! Now you have %2$d available clues to use in all incoming threads", nil), count, total] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        
    } failure:nil];
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