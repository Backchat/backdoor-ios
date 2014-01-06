//
//  YTViewHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTConfig.h"
#import "YTViewHelper.h"
#import "YTHelper.h"
#import "YTAppDelegate.h"
#import "YTApiHelper.h"

#import "YTFeedbackViewController.h"
#import "YTGabViewController.h"
#import "YTLoginViewController.h"
#import "YTMainViewController.h"
#import "YTSettingsViewController.h"
#import "YTViewController.h"
#import "YTWebViewController.h"
#import "YTNewGabViewController.h"
#import "YTSheetViewController.h"

#import <WBErrorNoticeView.h>
#import <Mixpanel.h>

@implementation YTViewHelper

+ (void)setup
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    delegate.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    delegate.usesSplitView = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    delegate.navController = [UINavigationController new];
    [delegate.navController.navigationBar setBackgroundImage:[YTHelper imageNamed:@"navbar3"] forBarMetrics:UIBarMetricsDefault];
    
    if(![YTHelper isV7]) {
        [[UIBarButtonItem appearance] setBackgroundImage:[[YTHelper imageNamed:@"baritem4"] resizableImageWithCapInsets:UIEdgeInsetsMake(5,5,5,5)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[YTHelper imageNamed:@"backbaritem4"] resizableImageWithCapInsets:UIEdgeInsetsMake(15,15,15,5)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setTintColor:[UIColor clearColor]];
    }
    else {
        [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
        delegate.navController.navigationBar.tintColor = [UIColor whiteColor];
    }

    delegate.window.backgroundColor = [UIColor colorWithRed:0x44/255.0 green:0x8d/255.0 blue:0x1f/255.0 alpha:1];

    if (delegate.usesSplitView) {
        delegate.detailsController = [UINavigationController new];
        delegate.splitController = [UISplitViewController new];
        delegate.splitController.viewControllers = @[delegate.navController, delegate.detailsController];
        delegate.splitController.delegate = delegate;

        delegate.window.rootViewController = delegate.splitController;
        
    } else {
        delegate.window.rootViewController = delegate.navController;
    }
    
    YTLoginViewController *loginViewController;
    loginViewController = [YTLoginViewController new];
    [delegate.navController pushViewController:loginViewController animated:NO];

    [delegate.window makeKeyAndVisible];
}

+ (void)closeSheetViewIfAny
{
    if([YTAppDelegate current].sheetView) {
        [[YTAppDelegate current].sheetView dismiss];
    }
}

+ (YTLoginViewController*)showLogin:(BOOL)animated
{
    YTAppDelegate *delegate = [YTAppDelegate current];

    [delegate.navController popToRootViewControllerAnimated:animated];

    return (YTLoginViewController*)delegate.navController.topViewController;
}

+ (void)hideLogin:(BOOL)animated
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    YTMainViewController *mainGabController = [YTMainViewController new];
    [delegate.navController pushViewController:mainGabController animated:animated];
}

+ (void)makeGabViewControllerTop: (YTGabViewController*) controller animated:(BOOL)animated
{
    [YTViewHelper closeSheetViewIfAny];

    YTAppDelegate *delegate = [YTAppDelegate current];

    if([delegate.navController.topViewController isKindOfClass:[YTLoginViewController class]]) {
        delegate.currentMainViewController = [YTMainViewController new];
        [delegate.navController pushViewController:delegate.currentMainViewController animated:NO];
        [delegate.currentMainViewController setupNavBar];
        [delegate.navController setNavigationBarHidden:NO animated:NO];
    }
    else {
        [delegate.navController popToViewController:delegate.currentMainViewController animated:NO];
    }
    
    [delegate.navController pushViewController:controller animated:animated];

    delegate.currentGabViewController = controller;
    
}

+ (void)showGabWithGabId:(NSNumber*)gab_id animated:(BOOL)animated
{
    YTGab* gab = [YTGab gabForId:gab_id];
    [YTViewHelper showGab:gab animated:animated];
}

+ (void)showGab:(YTGab*)gab animated:(BOOL)animated
{
    UIViewController* top = YTAppDelegate.current.navController.topViewController;
    if([top isKindOfClass:[YTGabViewController class]]) {
        YTGabViewController* gabController = (YTGabViewController*)top;
        if(gabController.gab.id.integerValue == gab.id.integerValue)
            return;
    }
    
    YTGabViewController *controller = [[YTGabViewController alloc] initWithGab:gab];
    [YTViewHelper makeGabViewControllerTop:controller animated:animated];
}

+ (void)showGabWithFriend:(YTFriend*)f animated:(BOOL)animated
{
    YTGabViewController* controller = [[YTGabViewController alloc] initWithFriend:f];
    [YTViewHelper makeGabViewControllerTop:controller animated:animated];
}

+ (void)showGabs:(BOOL)animated
{
    [YTViewHelper closeSheetViewIfAny];

    YTAppDelegate *delegate = [YTAppDelegate current];
    
    if([delegate.navController.topViewController isKindOfClass:[YTLoginViewController class]]) {
        delegate.currentMainViewController = [YTMainViewController new];
        [delegate.navController pushViewController:delegate.currentMainViewController animated:animated];
    }
    else {
        [delegate.navController popToViewController:delegate.currentMainViewController animated:animated];
    }
}

+ (void)showSettings
{
    [YTViewHelper closeSheetViewIfAny];

    YTAppDelegate *delegate = [YTAppDelegate current];
    YTSettingsViewController *controller = [YTSettingsViewController new];

    [delegate.navController pushViewController:controller animated:YES];
    /*TODO SPLITVIEW } else {
        delegate.navController.viewControllers = @[controller];
        
        [YTViewHelper showFeedback];
    }*/
}

static WBErrorNoticeView *notice = nil;

+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message
{    
    if (notice && [notice.title isEqualToString:title] && [notice.message isEqualToString:message]) {
        return;
    }
    
    void (^block)(BOOL) = ^(BOOL dismissedInteractively) {
        UIView* view = [YTAppDelegate current].navController.view;
        notice = [WBErrorNoticeView errorNoticeInView:view title:title message:message];
        notice.sticky = YES;
        notice.originY = [UIApplication sharedApplication].statusBarFrame.size.height;
        [notice setDismissalBlock:^(BOOL dismissedInteractively) {
            notice = nil;
        }];
        [notice show];
    };
    
    if (notice) {
        [notice setDismissalBlock:block];
        notice.delay = 0;
        [notice dismissNotice];
    } else {
        block(false);
    }
}

+ (void)hideAlert
{
    if(notice) {
        [notice dismissNotice];
        notice = nil;
    }
}

+ (void)invalidSessionLogout
{
    if([YTAppDelegate.current.navController.topViewController isKindOfClass:[YTLoginViewController class]])
        return;
    
    UIAlertView* alert;
    alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, your session has ended", nil)
                                       message:NSLocalizedString(@"Please login again", nil)
                                      delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];

    //we need to log out
    [YTAppDelegate.current.currentUser logout];
    [[YTViewHelper showLogin:YES] showLoginButtons:NO];
    
    [alert show];
}
@end
