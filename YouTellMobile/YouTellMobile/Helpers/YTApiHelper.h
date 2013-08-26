//
//  YTApiHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YTContact;

@interface YTApiHelper : NSObject

+ (NSURL*)baseUrl;

+ (void)toggleNetworkActivityIndicatorVisible:(BOOL)visible;

+ (void) sendJSONRequestToPath:(NSString*)path
                        method:(NSString*)method
                        params:(NSDictionary*)params
                       success:(void(^)(id JSON))success
                       failure:(void(^)(id JSON))failure;

+ (void) sendJSONRequestWithBlockingUIMessage:(NSString*)message
                                         path:(NSString*)path
                                       method:(NSString*)method
                                       params:(NSDictionary*)params
                                      success:(void(^)(id JSON))success
                                      failure:(void(^)(id JSON))failure;

+ (void)sendFeedback:(NSString*)content rating:(NSNumber*)rating success:(void(^)(id JSON))success;
+ (void)sendAbuseReport:(NSString*)content success:(void(^)(id JSON))success;

+ (void)getCluesForGab:(NSNumber*)gab_id success:(void(^)(id JSON))success;
+ (void)requestClue:(NSNumber*)gabId number:(NSNumber*)number success:(void(^)(id JSON))success;
+ (void)buyCluesWithReceipt:(NSString *)receipt success:(void(^)(id JSON))success;
+ (void)getFreeCluesWithReason:(NSString *)reason;

+ (void)checkUpdates;

+ (void)sendInviteText:(YTContact*)contact body:(NSString*)body success:(void(^)(id JSON))success;
@end