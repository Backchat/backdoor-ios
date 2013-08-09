//
//  YTFBHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FacebookSDK/FacebookSDK.h>

#import "YTContacts.h"

@interface YTFBHelper : NSObject

+ (bool)trySilentAuth;
+ (void)requestAuth;
+ (void)reauth;

+ (void)closeSession;
+ (BOOL)handleOpenUrl:(NSURL*)url;
+ (void)presentFeedDialog;
+ (void)presentRequestDialogWithContact:(NSString*)contact complete:(void(^)())complete;
+ (NSString*)avatarUrlWithFBId:(NSString*)FBId;
+ (void)fetchFriends:(void(^)(YTContacts* c))success;

@end
