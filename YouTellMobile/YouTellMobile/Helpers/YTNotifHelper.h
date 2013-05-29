//
//  YTNotifHelper.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTNotifHelper : NSObject

+ (BOOL)vibrationEnabled;
+ (BOOL)soundEnabled;

+ (void)setVibrationEnabled:(BOOL)enabled;
+ (void)setSoundEnabled:(BOOL)enabled;


+ (void)handleNotification:(NSDictionary*)userInfo;

@end
