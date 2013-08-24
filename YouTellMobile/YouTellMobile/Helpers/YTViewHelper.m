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
    
    
    [[UIBarButtonItem appearance] setBackgroundImage:[[YTHelper imageNamed:@"baritem4"] resizableImageWithCapInsets:UIEdgeInsetsMake(5,5,5,5)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[YTHelper imageNamed:@"backbaritem4"] resizableImageWithCapInsets:UIEdgeInsetsMake(15,15,15,5)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTintColor:[UIColor clearColor]];
    
    delegate.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    delegate.usesSplitView = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    delegate.navController = [UINavigationController new];
    [delegate.navController.navigationBar setBackgroundImage:[YTHelper imageNamed:@"navbar3"] forBarMetrics:UIBarMetricsDefault];
    
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

    YTMainViewController* mainController = [YTMainViewController new];
    delegate.currentMainViewController = mainController;
    [delegate.navController pushViewController:mainController animated:NO];
}

+ (void)endRefreshing
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    [delegate.currentMainViewController.refreshControl endRefreshing];
}

+ (void)closeSheetViewIfAny
{
    if([YTAppDelegate current].sheetView) {
        [[YTAppDelegate current].sheetView dismiss];
    }
}

+ (YTLoginViewController*) getOrCreateLoginView
{
    [YTViewHelper closeSheetViewIfAny];
    
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    UIViewController *topViewController = [delegate.navController topViewController];
    UIViewController *viewController = [topViewController presentedViewController];
    YTLoginViewController *loginViewController;
    
    if (![viewController isKindOfClass:[YTLoginViewController class]]) {
        loginViewController = [YTLoginViewController new];
        [topViewController presentViewController:loginViewController animated:NO completion:nil];
    }
    else
    {
        loginViewController = (YTLoginViewController*)viewController;

    }
    
    return loginViewController;
}

+ (void)showLogin
{
    [self getOrCreateLoginView];
}

+ (void)showLoginWithButtons
{
    [[self getOrCreateLoginView] showLoginButtons];
}

+ (void)hideLogin
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    UIViewController *topViewController = [delegate.navController topViewController];
    UIViewController *login = (UIViewController*)[topViewController presentedViewController];
    if ([login isKindOfClass:[YTLoginViewController class]]) {
        login.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        login.providesPresentationContextTransitionStyle = YES;
        
        [topViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [self showGabs];
}

+ (void)makeGabViewControllerTop: (YTGabViewController*) controller animated:(BOOL)animated
{
    [YTViewHelper closeSheetViewIfAny];

    YTAppDelegate *delegate = [YTAppDelegate current];
    
    if (delegate.usesSplitView) {
        [YTViewHelper loadDetailsController:controller];
    } else {
        [delegate.navController popToRootViewControllerAnimated:NO];
        [delegate.navController pushViewController:controller animated:animated];
    }
    
    delegate.currentGabViewController = controller;
}   

+ (void)showGabWithGabId:(NSNumber*)gab_id
{
    YTGab* gab = [YTGab gabForId:gab_id];
    gab.needs_update = @true;
    [YTViewHelper showGab:gab];
}

+ (void)showGab:(YTGab*)gab
{
    [YTViewHelper showGab:gab animated:YES];
}

+ (void)showGab:(YTGab*)gab animated:(BOOL)animated
{
    YTGabViewController *controller = [[YTGabViewController alloc] initWithGab:gab];
    [YTViewHelper makeGabViewControllerTop:controller animated:animated];
}

+ (void)showGabWithFriend:(YTFriend*)f
{
    YTGabViewController* controller = [[YTGabViewController alloc] initWithFriend:f];
    [YTViewHelper makeGabViewControllerTop:controller animated:YES];
 
}

+ (void)loadSettingsController:(UIViewController*)controller
{
    [YTViewHelper closeSheetViewIfAny];

    YTAppDelegate *delegate = [YTAppDelegate current];

    if (!delegate.usesSplitView) {
        [delegate.navController pushViewController:controller animated:YES];
    } else {
        [YTViewHelper loadDetailsController:controller];       
    }    
}

+ (void)loadDetailsController:(UIViewController*)controller
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    delegate.detailsController.viewControllers = @[controller];
}

+ (void)showTerms
{
    [YTViewHelper loadSettingsController:[[YTWebViewController alloc] initWithPage:@"terms"]];
}

+ (void)showPrivacy
{
    [YTViewHelper loadSettingsController:[[YTWebViewController alloc] initWithPage:@"privacy"]];
}

+ (void)showFeedback
{
    [YTViewHelper loadSettingsController:[YTFeedbackViewController new]];
}

+ (void)showGabs
{
    [YTViewHelper closeSheetViewIfAny];

    YTAppDelegate *delegate = [YTAppDelegate current];
    
    if (!delegate.usesSplitView) {
        [delegate.navController popToRootViewControllerAnimated:YES];
    }
    else {
        YTViewController *blank = [YTViewController new];
        YTMainViewController *controller = [YTMainViewController new];
        delegate.detailsController.viewControllers = @[blank];
        delegate.navController.viewControllers = @[controller];
        delegate.currentMainViewController = controller;
    }
}

+ (void)showSettings
{
    [YTViewHelper closeSheetViewIfAny];

    YTAppDelegate *delegate = [YTAppDelegate current];
    YTSettingsViewController *controller = [YTSettingsViewController new];

    if (!delegate.usesSplitView) {
        [delegate.navController pushViewController:controller animated:YES];
    } else {
        delegate.navController.viewControllers = @[controller];
        
        [YTViewHelper showFeedback];
    }

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

@end
