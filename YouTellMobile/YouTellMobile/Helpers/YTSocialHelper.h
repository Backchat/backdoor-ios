//
//  YTSocialHelper.h
//  Backdoor
//
//  Created by Łukasz S on 6/5/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface YTSocialHelper : NSObject

+ (YTSocialHelper*)sharedInstance;
- (BOOL)isGPP;
- (BOOL)isFacebook;
- (void)presentShareDialog;
- (void)fetchUserData:(void(^)(NSDictionary* data))success;

- (void)logoutProviders;
@end

extern NSString* const YTSocialLoggedInAccessTokenKey;
extern NSString* const YTSocialLoggedInProviderKey;
extern NSString* const YTSocialLoggedIn;
extern NSString* const YTSocialLoginFailed;
extern NSString* const YTSocialLoggedInNameKey;
extern NSString* const YTSocialReauthSuccess;