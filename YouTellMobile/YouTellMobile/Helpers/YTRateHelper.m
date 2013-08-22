//
//  YTRateHelper.m
//  Backdoor
//
//  Created by Łukasz S on 7/26/13.
//  Copyright (c) 2013 4WT. All rights reserved.
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
    
    if(uses == CONFIG_RATING_USES_CANCELLED)
        return;
    
    uses -= 1;
    
    if (uses <= 0) {
        [[iRate sharedInstance] promptForRating];
    }
    else {
        [defs setInteger:uses forKey:key];
        [defs synchronize];
    }
}

- (void)iRateCouldNotConnectToAppStore:(NSError *)error
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *key = @"rate_remaining_uses";
    [defs setInteger:1 forKey:key];
    [defs synchronize];
}

- (void)iRateUserDidDeclineToRateApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *key = @"rate_remaining_uses";
    [defs setInteger:CONFIG_RATING_USES_CANCELLED forKey:key];
    [[Mixpanel sharedInstance] track:@"Declined Rate Request"];
    [defs synchronize];

}

- (void)iRateUserDidRequestReminderToRateApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *key = @"rate_remaining_uses";
    [defs setInteger:CONFIG_RATING_USES_DELAYED forKey:key];
    [[Mixpanel sharedInstance] track:@"Delayed Rate Request"];
    [defs synchronize];

}

- (void)iRateUserDidAttemptToRateApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *key = @"rate_remaining_uses";
    [defs setInteger:CONFIG_RATING_USES_CANCELLED forKey:key];
    [[Mixpanel sharedInstance] track:@"Accepted Rate Request"];
    [defs synchronize];
    
}


@end
