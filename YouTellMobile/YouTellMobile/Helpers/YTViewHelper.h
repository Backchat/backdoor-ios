//
//  YTViewHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTFriend.h"

@interface YTViewHelper : NSObject

+ (void)setup;
+ (void)refreshViews;
+ (void)endRefreshing;

+ (void)showLogin;
+ (void)showLoginWithButtons;
+ (void)hideLogin;
+ (void)showTerms;
+ (void)showPrivacy;
+ (void)showGabWithId:(NSNumber*)gabId;
+ (void)showGab;
+ (void)showGabWithFriend:(YTFriend*)f;
+ (void)showFeedback;
+ (void)showGabs;
+ (void)showSettings;
+ (void)loadSettingsController:(UIViewController*)controller;
+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message;
+ (void)hideAlert;
@end
