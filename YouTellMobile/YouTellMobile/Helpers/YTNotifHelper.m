//
//  YTNotifHelper.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#import "YTNotifHelper.h"
#import "YTModelHelper.h"

@implementation YTNotifHelper

+ (BOOL)vibrationEnabled{
    return [[YTModelHelper settingsForKey:@"notif_vibration"] isEqualToString:@"1"] || [[YTModelHelper settingsForKey:@"notif_vibration"] isEqualToString:@""];
}

+ (BOOL)soundEnabled
{
    return [[YTModelHelper settingsForKey:@"notif_sound"] isEqualToString:@"1"] || [[YTModelHelper settingsForKey:@"notif_sound"] isEqualToString:@""];
}

+ (void)setVibrationEnabled:(BOOL)enabled
{
    [YTModelHelper setSettingsForKey:@"notif_vibration" value:(enabled ? @"1" : @"0")];
}
+ (void)setSoundEnabled:(BOOL)enabled
{
    [YTModelHelper setSettingsForKey:@"notif_sound" value:(enabled ? @"1" : @"0")];
}

+ (void)handleNotification:(NSDictionary*)userInfo;
{
    if ([YTNotifHelper vibrationEnabled]) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        NSLog(@"vibrating");
    }
    
    // FIXME: Use custom sound instead
    if ([YTNotifHelper soundEnabled]) {
        AudioServicesPlaySystemSound(1003);
        NSLog(@"playing sound");
    }
}
@end
