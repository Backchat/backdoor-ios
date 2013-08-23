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

NSString * const YTRATEKEY = @"rate_remaining_uses";

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

- (void)reset
{
    [[NSUserDefaults standardUserDefaults] setInteger:CONFIG_RATING_USES forKey:YTRATEKEY];
}

- (void)run
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    
    if (![defs objectForKey:YTRATEKEY]) {
        [defs setInteger:CONFIG_RATING_USES forKey:YTRATEKEY];
    }
    
    NSInteger uses = [defs integerForKey:YTRATEKEY];
    
    if(uses == CONFIG_RATING_USES_CANCELLED)
        return;
    
    uses -= 1;
    
    if (uses <= 0) {
        [[iRate sharedInstance] promptForRating];
    }
    else {
        [defs setInteger:uses forKey:YTRATEKEY];
        [defs synchronize];
    }
}

- (void)iRateCouldNotConnectToAppStore:(NSError *)error
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setInteger:1 forKey:YTRATEKEY];
    [defs synchronize];
}

- (void)iRateUserDidDeclineToRateApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setInteger:CONFIG_RATING_USES_CANCELLED forKey:YTRATEKEY];
    [[Mixpanel sharedInstance] track:@"Declined Rate Request"];
    [defs synchronize];

}

- (void)iRateUserDidRequestReminderToRateApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setInteger:CONFIG_RATING_USES_DELAYED forKey:YTRATEKEY];
    [[Mixpanel sharedInstance] track:@"Delayed Rate Request"];
    [defs synchronize];

}

- (void)iRateUserDidAttemptToRateApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setInteger:CONFIG_RATING_USES_CANCELLED forKey:YTRATEKEY];
    [[Mixpanel sharedInstance] track:@"Accepted Rate Request"];
    [defs synchronize];
    
}


@end
