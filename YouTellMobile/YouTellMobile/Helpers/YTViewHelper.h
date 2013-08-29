//
//  YTViewHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTFriend.h"
#import "YTGab.h"

@class YTLoginViewController;

@interface YTViewHelper : NSObject

+ (void)setup;

//destroys all windows and shows login
+ (YTLoginViewController*)showLogin:(BOOL)animated;

+ (void)showGab:(YTGab*)gab animated:(BOOL)animated;
+ (void)showGabWithFriend:(YTFriend*)f animated:(BOOL)animated;
+ (void)showGabs:(BOOL)animated;

+ (void)showSettings;

+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message;
+ (void)hideAlert;

+ (void)invalidSessionLogout;

@end
