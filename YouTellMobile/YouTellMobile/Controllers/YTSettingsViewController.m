//
//  YTSettingsViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Mixpanel.h>

#import "YTConfig.h"
#import "YTSettingsViewController.h"
#import "YTViewHelper.h"
#import "YTFBHelper.h"
#import "YTAppDelegate.h"
#import "YTFBHelper.h"
#import "YTGPPHelper.h"
#import "YTHelpSettingsViewController.h"
#import "YTViewHelper.h"
#import "YTWebViewController.h"
#import "YTPrivacySettingsViewController.h"
#import "YTInviteSettingsViewController.h"
#import "YTApiHelper.h"
#import "YTModelHelper.h"
#import "YTNotificationSettingsViewController.h"
#import "YTSocialHelper.h"
#import "iVersion.h"
#import "YTLoginViewController.h"

@implementation YTSettingsViewController

# pragma mark UIViewController methods

- (void)viewDidLoad
{
    NSString *freeCluesTitle = (YTAppDelegate.current.currentUser.userHasShared) ? NSLocalizedString(@"Share with Friends", nil) : NSLocalizedString(@"Free Clues", nil);

    NSString* versionString = [NSString stringWithFormat:NSLocalizedString(@"Version %@", nil), [iVersion sharedInstance].applicationVersion];
    
    self.tableData = @[
        @[
            @[@"icon_notifications3", NSLocalizedString(@"Notifications", nil), @"showNotifications"]
        ],
        @[
            @[@"icon_facebook3", freeCluesTitle, @"showInvite"]
        ], @[
            @[@"icon_privacy3", NSLocalizedString(@"Privacy & Abuse", nil), @"showPrivacy"]
        ], @[
            @[@"icon_help3", NSLocalizedString(@"Help & About Us", nil), @"showHelp"]
        ], @[
            @[@"", versionString, @""]
            ]
    ];
    
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(showGabsWithAnimation)];

    UIBarButtonItem *logoutItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(signOut)];
    
    UIBarButtonItem *crashItem = [[UIBarButtonItem alloc] initWithTitle:@"Crash" style:UIBarButtonItemStyleBordered target:self action:@selector(crash)];
    
    UIBarButtonItem *cluesItem = [[UIBarButtonItem alloc] initWithTitle:@"Add clues" style:UIBarButtonItemStyleBordered target:self action:@selector(cluesButtonWasClicked)];

    UIBarButtonItem *rateItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Rate", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(rateButtonWasClicked)];
    
    UIBarButtonItem *inviteItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Share", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(shareButtonWasClicked)];
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[logoutItem]];
    
    if (CONFIG_CLUES_BUTTON) {
        [items addObject:cluesItem];
    } else {
        [items addObject:inviteItem];
    }
    
/*    if (CONFIG_CRASH_BUTTON) {
        [items addObject:crashItem];
    } else {
        [items addObject:rateItem];
    }*/
    
    self.navigationItem.rightBarButtonItems = items;
}

- (void)showGabsWithAnimation
{
    [YTViewHelper showGabs:YES];
}

- (void)signOut
{
    [YTAppDelegate.current.currentUser logout];
    [[YTViewHelper showLogin:YES] showLoginButtons:NO];
}

- (void)showNotifications
{
    [YTAppDelegate.current.navController pushViewController:[[YTNotificationSettingsViewController alloc]init] animated:YES];
}

- (void)showInvite
{
    [[Mixpanel sharedInstance] track:@"Tapped Share With Friends (Free Clues) Settings Button"];
    [YTAppDelegate.current.navController pushViewController:[[YTInviteSettingsViewController alloc]init] animated:YES];
}

- (void)showPrivacy
{
    [YTAppDelegate.current.navController pushViewController:[[YTPrivacySettingsViewController alloc]init] animated:YES];
}

- (void)showHelp
{
    [YTAppDelegate.current.navController pushViewController:[[YTHelpSettingsViewController alloc]init] animated:YES];
}

- (void)cluesButtonWasClicked
{
    [YTApiHelper getFreeCluesWithReason:@"debug"];
}

- (void)rateButtonWasClicked
{
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&type=Purple+Software", CONFIG_APPLE_ID];
    NSURL *url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
    [[Mixpanel sharedInstance] track:@"Tapped Rate Button"];
}

- (void)inviteButtonWasClicked
{
    [YTFBHelper presentRequestDialogWithContact:nil complete:nil];
    [[Mixpanel sharedInstance] track:@"Tapped Invite Button"];
}

- (void)shareButtonWasClicked
{
    [[YTSocialHelper sharedInstance] presentShareDialog];

    [[Mixpanel sharedInstance] track:@"Tapped Share Button"];
}

@end
