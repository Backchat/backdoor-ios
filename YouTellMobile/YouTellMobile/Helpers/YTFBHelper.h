//
//  YTFBHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FacebookSDK/FacebookSDK.h>

@interface YTFBHelper : NSObject

+ (bool)trySilentAuth;
+ (void)requestAuth;

+ (void)closeSession;
+ (BOOL)handleOpenUrl:(NSURL*)url;
+ (void)presentFeedDialog;
+ (void)presentRequestDialogWithContact:(NSString*)contact complete:(void(^)())complete;
+ (NSString*)avatarUrlWithFBId:(NSString*)FBId;

@end
