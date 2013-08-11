//
//  YTRateHelper.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTRateHelper.h"
#import "YTConfig.h"

#import <Mixpanel.h>
#import <iRate.h>

@implementation YTRateHelper

+ (YTRateHelper*)sharedInstance
{
    static YTRateHelper *instance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        instance = [YTRateHelper new];
    });
    return instance;
}

- (void)setup
{
    [iRate sharedInstance].promptAtLaunch = NO;
    [iRate sharedInstance].appStoreID = CONFIG_APPLE_ID_INT;
    [iRate sharedInstance].delegate = self;
}

- (void)run
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *key = @"rate_remaining_uses";
    
    if (![defs objectForKey:key]) {
        [defs setInteger:CONFIG_RATING_USES forKey:key];
    }
    
    NSInteger uses = [defs integerForKey:key];
    
    uses -= 1;
    
    if (uses <= 0) {
        [[iRate sharedInstance] promptForRating];
        uses = 1;
    }
    
    [defs setInteger:uses forKey:key];

}

- (void)iRateCouldNotConnectToAppStore:(NSError *)error
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *key = @"rate_remaining_uses";
    [defs setInteger:1 forKey:key];
}

- (void)iRateUserDidDeclineToRateApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *key = @"rate_remaining_uses";
    [defs setInteger:CONFIG_RATING_USES_CANCELLED forKey:key];
    [[Mixpanel sharedInstance] track:@"Declined Rate Request"];

}

- (void)iRateUserDidRequestReminderToRateApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *key = @"rate_remaining_uses";
    [defs setInteger:CONFIG_RATING_USES_DELAYED forKey:key];
    [[Mixpanel sharedInstance] track:@"Delayed Rate Request"];

}

- (void)iRateUserDidAttemptToRateApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *key = @"rate_remaining_uses";
    [defs setInteger:999999999 forKey:key];
    [[Mixpanel sharedInstance] track:@"Accepted Rate Request"];
}


@end
