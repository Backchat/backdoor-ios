//
//  YTSocialHelper.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTSocialHelper.h"
#import "YTGPPHelper.h"
#import "YTFBHelper.h"
#import "YTAppDelegate.h"
#import "YTModelHelper.h"

@implementation YTSocialHelper

+ (YTSocialHelper*)sharedInstance
{
    static YTSocialHelper *instance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        instance = [YTSocialHelper new];
    });
    return instance;
}

- (BOOL)isGPP
{
    return YTAppDelegate.current.currentUser.socialProvider == YTSocialProviderGPP;
}

- (BOOL)isFacebook
{
    return YTAppDelegate.current.currentUser.socialProvider == YTSocialProviderFacebook;
}

- (void)presentShareDialog
{
    if ([self isGPP]) {
        [[YTGPPHelper sharedInstance] presentShareDialog];
    } else if ([self isFacebook]) {
        [YTFBHelper presentFeedDialog];
    }
}

- (void)fetchUserData:(void(^)(NSDictionary* data))success;
{
    if([self isGPP]) {
        [[YTGPPHelper sharedInstance] fetchUserData:success];
    }
    else {
        [YTFBHelper fetchUserData:success];
    }
}

- (void)logoutProviders
{
    [[YTGPPHelper sharedInstance] signOut];
    [YTFBHelper closeSession];
}

@end

NSString* const YTSocialLoggedIn = @"YTSocialLoggedIn";
NSString* const YTSocialLoginFailed = @"YTSocialLoginFailed";
NSString* const YTSocialLoggedInAccessTokenKey = @"YTSocialLoggedInAccessTokenKey";
NSString* const YTSocialLoggedInNameKey = @"YTSocialLoggedInNameKey";
NSString* const YTSocialLoggedInProviderKey = @"YTSocialLoggedInProviderKey";
NSString* const YTSocialReauthSuccess = @"YTSocialReauthSuccess";
