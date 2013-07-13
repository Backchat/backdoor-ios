//
//  YTApiHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTApiHelper : NSObject

+ (void)setup;
+ (void)login:(void(^)(id JSON))success;
+ (void)resetUserInfo;
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

+ (void)syncGabs;
+ (void)syncGabWithId:(NSNumber *)gab_id popup:(BOOL)popup;

+ (void)getUserInfo:(void(^)(id JSON))success;
+ (void)updateUserInfo:(void(^)(id JSON))success;
+ (bool)isNewUser;
+ (void)setNewUser:(bool)new_user;

+ (void)sendFeedback:(NSString*)content rating:(NSNumber*)rating success:(void(^)(id JSON))success;
+ (void)sendAbuseReport:(NSString*)content success:(void(^)(id JSON))success;
+ (void)deleteGab:(NSNumber*)gabId success:(void(^)(id JSON))success;
+ (void)tagGab:(NSNumber*)gabId tag:(NSString*)tag success:(void(^)(id JSON))success;
+ (void)clearUnread:(NSNumber*)gabId;

+ (void)getCluesForGab:(NSNumber*)gab_id success:(void(^)(id JSON))success;
+ (void)requestClue:(NSNumber*)gabId number:(NSNumber*)number success:(void(^)(id JSON))success;
+ (void)buyCluesWithReceipt:(NSString *)receipt success:(void(^)(id JSON))success;
+ (void)getFreeCluesWithReason:(NSString *)reason;
+ (void)getFeaturedUsers;
+ (void)getFriends;
+ (void)updateSettingsWithKey:(NSString*)key value:(id)value;
+ (void)checkUpdates;


@end
