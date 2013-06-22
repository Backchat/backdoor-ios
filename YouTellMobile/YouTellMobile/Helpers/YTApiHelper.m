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
#import "YTConfig.h"
#import "YTAppDelegate.h"
#import "YTHelper.h"
#import "YTApiHelper.h"
#import "YTModelHelper.h"
#import "YTViewHelper.h"
#import "YTContactHelper.h"

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

+ (void)updateUserInfo:(NSDictionary*)params
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSMutableDictionary *sentInfo = delegate.sentInfo;
    
    /*
     if (params[@"fb_data"]) {
     sentInfo[@"fb_data"] = params[@"fb_data"];
     }
     
     if (params[@"gpp_data"]) {
     sentInfo[@"gpp_data"] = params[@"gpp_data"];
     }
     */
    if (params[@"device_token"]) {
        sentInfo[@"device_token"] = params[@"device_token"];
    }
}

+ (NSDictionary*)userParams
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSMutableDictionary *userInfo = delegate.userInfo;
    NSMutableDictionary *sentInfo = delegate.sentInfo;
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
    
    if (userInfo[@"device_token"] && ![userInfo[@"device_token"] isEqual:sentInfo[@"device_token"]]) {
        result[@"device_token"] = userInfo[@"device_token"];
    }
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
    NSDictionary *userParams = [YTApiHelper userParams];
    if (!userParams) {
        if (failure != nil) {
            failure(nil);
        }
        return;
    }
    
    [myParams addEntriesFromDictionary:userParams];
    
    myParams[@"sync_time"] = [YTModelHelper settingsForKey:@"sync_time"];
    myParams[@"sync_uid"] = [YTModelHelper settingsForKey:@"sync_uid"];
    myParams[@"db_timestamp"] = [YTModelHelper settingsForKey:@"db_timestamp"];
    NSMutableURLRequest *request = [client requestWithMethod:method path:path parameters:myParams];
        
    [request setTimeoutInterval:CONFIG_TIMEOUT];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [YTApiHelper toggleNetworkActivityIndicatorVisible:NO];
            [YTApiHelper updateUserInfo:userParams];
            
            if(![JSON[@"status"] isEqualToString:@"ok"]) {
                if (failure != nil) {
                    failure(JSON);
                }
                return;
            }
            
            [Flurry setUserID:JSON[@"response"][@"sync_data"][@"sync_uid"]];
            
            NSDictionary *sync_data = JSON[@"response"][@"sync_data"];
            if (sync_data != nil) {
                [YTModelHelper loadSyncData:sync_data];
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
            [YTViewHelper showNetworkErrorAlert];            
            NSLog(@"%@", [error debugDescription]);
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
}


+ (void)autoSync:(BOOL)quiet
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    if ([delegate.autoSyncLock tryLock] == NO) {
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    if (delegate.currentMainViewController && delegate.currentMainViewController.selectedGabId) {
        params[@"gab_id"] = delegate.currentMainViewController.selectedGabId;
    }
    
    if (delegate.currentGabViewController && delegate.currentGabViewController.gab) {
        params[@"gab_id"] = [delegate.currentGabViewController.gab valueForKey:@"id"];
    }
    
    [YTApiHelper sendJSONRequestToPath:@"/sync" method:@"POST" params:params success:^(id JSON) {
        [delegate.autoSyncLock unlock];
        [YTViewHelper refreshViews];
        [YTViewHelper endRefreshing];
        
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            YTAppDelegate *delegate = [YTAppDelegate current];
            if (delegate.autoSyncGabId) {
                [YTViewHelper showGabWithId:delegate.autoSyncGabId];
                delegate.autoSyncGabId = nil;
            }
            
        });
        
        
    } failure:^(id JSON) {
        [delegate.autoSyncLock unlock];
        [YTViewHelper endRefreshing];
    }];
}

+ (void)checkUid:(NSString*)uid success:(void(^)(id JSON))success failure:(void(^)(id JSON))failure
{
    [YTApiHelper sendJSONRequestToPath:@"/check-uid"
                                method:@"POST"
                                params:@{@"uid": uid}
                               success:success failure:failure];
}


+ (void)deleteGab:(NSNumber*)gabId success:(void(^)(id JSON))success
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [YTModelHelper clearGab:gabId];
        [YTViewHelper refreshViews];

        if(gabId.integerValue >= 0) {
            [YTApiHelper sendJSONRequestToPath:@"/clear-gab" method:@"POST" params:@{@"id": gabId} success:success failure:nil];
        }
    }];
    
    
    [Flurry logEvent:@"Deleted_Thread"];
}

+ (void)tagGab:(NSNumber*)gabId tag:(NSString*)tag success:(void(^)(id JSON))success
{
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Updating thread", nil)
                                                 path:@"/tag-gab"
                                               method:@"POST"
                                               params:@{@"id": gabId, @"tag": tag}
                                              success:success
                                              failure:nil];
    [Flurry logEvent:@"Tagged_Thread"];
}

+ (void)requestClue:(NSNumber*)gabId number:(NSNumber*)number success:(void(^)(id JSON))success;
{
    [YTApiHelper sendJSONRequestToPath:@"/request-clue"
                                method:@"POST"
                                params:@{@"gab_id": gabId, @"number": number}
                               success:success failure:nil];
    
    [Flurry logEvent:@"Requested_Clue"];
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
    
    [YTApiHelper sendJSONRequestToPath:@"/featured-users" method:@"POST" params:@{} success:^(id JSON) {
        
        [YTAppDelegate current].featuredUsers = JSON[@"users"];
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

@end
