//
//  YTSocialHelper.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTSocialHelper.h"
#import "YTGPPHelper.h"
#import "YTFBHelper.h"
#import "YTViewHelper.h"
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

- (void)setup
{
    self.loginViewEnabled = NO;
    self.loggedIn = [NSMutableDictionary new];
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

- (void)enableLoginView:(BOOL)enabled
{
    self.loginViewEnabled = enabled;
    NSLog(@"enabled: %d, logged in: %d", enabled, [self isLoggedIn]);
    if (enabled) {
        [self toggleLoginView];
    }
}

- (void)toggleLoginView
{
    [YTViewHelper toggleLogin:![self isLoggedIn]];
}

- (void)setLoggedIn:(NSString *)provider loggedIn:(BOOL)loggedIn
{
    if (provider) {
        self.loggedIn[provider] = [NSNumber numberWithBool:loggedIn];
    } else {
        self.loggedIn = [NSMutableDictionary new];
    }
    
    if (self.loginViewEnabled) {
        [self toggleLoginView];
    }
}

- (BOOL)isLoggedIn
{
    BOOL ret = NO;
    
    for(NSString *key in self.loggedIn.allKeys) {
        if ([self.loggedIn[key] isEqualToNumber:@1]) {
            ret = YES;
        }
    }
    
    return ret;
}

@end
