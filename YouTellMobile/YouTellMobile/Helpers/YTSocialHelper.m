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
    return [[YTAppDelegate current].userInfo[@"provider"] isEqualToString:@"gpp"];
}

- (BOOL)isFacebook
{
    return [[YTAppDelegate current].userInfo[@"provider"] isEqualToString:@"facebook"];
}

- (void)presentShareDialog
{
    if ([self isGPP]) {
        [[YTGPPHelper sharedInstance] presentShareDialog];
    } else if ([self isFacebook]) {
        [YTFBHelper presentFeedDialog];
    }
}

- (void)fetchUserData
{
    if([self isGPP]) {
        [[YTGPPHelper sharedInstance] fetchUserData];
    }
    else {
        [YTFBHelper fetchUserData];
    }
}

- (void)reauthProviders
{
    NSString* whichProvider = [YTModelHelper settingsForKey:@"logged_in_provider"];
    if([whichProvider isEqualToString:@"facebook"])
        [YTFBHelper reauth];
    else
        [[YTGPPHelper sharedInstance] reauth];
}

- (void)logoutProviders
{
    [[YTGPPHelper sharedInstance] signOut];
    [YTFBHelper closeSession];
}

@end
