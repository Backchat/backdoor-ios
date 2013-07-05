//
//  YTSocialHelper.m
//  Backdoor
//
//  Created by Łukasz S on 6/5/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTSocialHelper.h"
#import "YTGPPHelper.h"
#import "YTFBHelper.h"
#import "YTAppDelegate.h"

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

@end
