//
//  YTViewHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTFriend.h"
#import "YTGab.h"

@interface YTViewHelper : NSObject

+ (void)setup;
+ (void)endRefreshing;

+ (void)showLogin;
+ (void)showLoginWithButtons;
+ (void)hideLogin;
+ (void)showTerms;
+ (void)showPrivacy;
+ (void)showGab:(YTGab*)gab;
+ (void)showGabWithGabId:(NSNumber*)gab_id;
+ (void)showGabWithFriend:(YTFriend*)f;
+ (void)showFeedback;
+ (void)showGabs;
+ (void)showSettings;
+ (void)loadSettingsController:(UIViewController*)controller;
+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message;
+ (void)hideAlert;
@end
