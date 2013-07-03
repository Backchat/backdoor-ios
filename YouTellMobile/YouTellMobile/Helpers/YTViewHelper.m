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

    [YTViewHelper showGabs];
    
    [delegate.window makeKeyAndVisible];
}

+ (void)refreshViews
{
    
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    [delegate.currentMainViewController reloadData];
    [delegate.currentGabViewController reloadData];
}

+ (void)endRefreshing
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    [delegate.currentMainViewController.refreshControl endRefreshing];
}

+ (void)showLogin
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    UIViewController *topViewController = [delegate.navController topViewController];
    UIViewController *viewController = [topViewController presentedViewController];
    
    if (![viewController isKindOfClass:[YTLoginViewController class]]) {
        YTLoginViewController *loginViewController = [YTLoginViewController new];
        [topViewController presentViewController:loginViewController animated:NO completion:nil];
    } else {
        YTLoginViewController *loginViewController = (YTLoginViewController*)viewController;
        [loginViewController loginFailed];
    }
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

+ (void)showGabWithId:(NSNumber*)gabId receiver:(NSDictionary*)receiver
{
    YTGabViewController *controller = [YTGabViewController new];
    controller.gabId = gabId;
    
    YTAppDelegate *delegate = [YTAppDelegate current];

    
    if (delegate.usesSplitView) {
        [YTViewHelper loadDetailsController:controller];
    } else {
        if ([delegate.navController.topViewController isKindOfClass:[YTGabViewController class]]) {
            YTGabViewController *gabView = (YTGabViewController*)delegate.navController.topViewController;
            if ([[gabView.gab valueForKey:@"id"] isEqualToNumber:gabId]) {
                return;
            }
        }
        
        if (![delegate.navController.topViewController isKindOfClass:[YTMainViewController class]]) {
            [delegate.navController popToRootViewControllerAnimated:NO];
        }
        
        [delegate.navController pushViewController:controller animated:YES];
    }
    
    if (receiver) {
        [controller.sendHelper.contactWidget selectContact:receiver];
        [controller.inputView.textView becomeFirstResponder];
    } else if (!gabId) {
        [controller.sendHelper.contactWidget.textField becomeFirstResponder];
    }
    
    delegate.currentGabViewController = controller;
}

+ (void)showGabWithId:(NSNumber*)gabId
{
    [YTViewHelper showGabWithId:gabId receiver:nil];
}

+ (void)showGabWithReceiver:(NSDictionary*)receiver
{
    [YTViewHelper showGabWithId:nil receiver:receiver];
}

+ (void)showGab
{
    [[YTAppDelegate current].currentMainViewController deselectSelectedGab:YES];
    [YTViewHelper showGabWithId:nil];
}

+ (void)loadSettingsController:(UIViewController*)controller
{
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
    YTAppDelegate *delegate = [YTAppDelegate current];
    YTMainViewController *controller = [YTMainViewController new];
    
    if (!delegate.usesSplitView) {
        
        if ([delegate.navController.viewControllers count] == 0) {
            delegate.navController.viewControllers = @[controller];
            delegate.currentMainViewController = controller;
        } else {
            [delegate.navController popToRootViewControllerAnimated:YES];
        }

    } else {
        YTViewController *blank = [YTViewController new];
        delegate.detailsController.viewControllers = @[blank];
        delegate.navController.viewControllers = @[controller];
        delegate.currentMainViewController = controller;

    }
    
    delegate.currentMainViewController.tableView.contentOffset = CGPointMake(0, delegate.currentMainViewController.searchBar.frame.size.height);
    
}

+ (void)showSettings
{
    [[Mixpanel sharedInstance] track:@"Tapped Settings Button"];
    YTAppDelegate *delegate = [YTAppDelegate current];
    YTSettingsViewController *controller = [YTSettingsViewController new];

    if (!delegate.usesSplitView) {
        [delegate.navController pushViewController:controller animated:YES];
    } else {
        delegate.navController.viewControllers = @[controller];
        
       // delegate.currentMainViewController = nil;
       // delegate.currentGabViewController = nil;

        [YTViewHelper showFeedback];
    }

}

+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message
{
    static WBErrorNoticeView *notice = nil;
    
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


@end
