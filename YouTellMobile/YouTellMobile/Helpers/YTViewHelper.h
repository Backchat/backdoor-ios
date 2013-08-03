//
//  YTViewHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTViewHelper : NSObject

+ (void)setup;
+ (void)refreshViews;
+ (void)endRefreshing;

+ (void)showLogin;
+ (void)showLoginButtons:(int)which;
+ (void)showLoginFailed;
+ (void)hideLogin;
+ (void)showTerms;
+ (void)showPrivacy;
+ (void)showGabWithId:(NSNumber*)gabId;
+ (void)showGabWithReceiver:(NSDictionary*)receiver;
+ (void)showGab;
+ (void)showFeedback;
+ (void)showGabs;
+ (void)showSettings;
+ (void)loadSettingsController:(UIViewController*)controller;
+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message;
+ (void)hideAlert;
@end
