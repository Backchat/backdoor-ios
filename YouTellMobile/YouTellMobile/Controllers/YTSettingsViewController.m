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

@implementation YTSettingsViewController

# pragma mark UIViewController methods

- (void)viewDidLoad
{
    NSString *freeCluesTitle = ([YTModelHelper userHasShared]) ? NSLocalizedString(@"Share with Friends", nil) : NSLocalizedString(@"Free Clues", nil);

    self.tableData = @[
        @[
            @[@"icon_notifications3", NSLocalizedString(@"Notifications", nil), @"showNotifications"]
        ],
        @[
            @[@"icon_facebook3", freeCluesTitle, @"showInvite"]
        ], @[
            /*@[@"icon_account2.png", NSLocalizedString(@"Your Account", nil), @"showYourAccount"],*/
            @[@"icon_privacy3", NSLocalizedString(@"Privacy & Abuse", nil), @"showPrivacy"]
        ],  /*@[
            @[@"icon_chat2.png", NSLocalizedString(@"Chat Settings", nil), @"showChatSettings"]
        ] @[
            @[@"icon_lang2.png", NSLocalizedString(@"Language", nil), @"showLanguage"]
        ], */ @[
            @[@"icon_help3", NSLocalizedString(@"Help & About Us", nil), @"showHelp"]
        ]
    ];
    
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:[YTViewHelper class] action:@selector(showGabs)];

    UIBarButtonItem *logoutItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout", nil) style:UIBarButtonItemStyleBordered target:[YTAppDelegate current] action:@selector(signOut)];
    
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
    
    if (CONFIG_CRASH_BUTTON) {
        [items addObject:crashItem];
    } else {
        [items addObject:rateItem];
    }
    self.navigationItem.rightBarButtonItems = items;
}


- (void)showNotifications
{
    [[Mixpanel sharedInstance] track:@"Tapped Notification Settings Button"];
    [YTViewHelper loadSettingsController:[[YTNotificationSettingsViewController alloc]init]];
}

- (void)showInvite
{
    [[Mixpanel sharedInstance] track:@"Tapped Share With Friends (Free Clues) Settings Button"];

    [YTViewHelper loadSettingsController:[[YTInviteSettingsViewController alloc]init]];
}

- (void)showPrivacy
{
    [[Mixpanel sharedInstance] track:@"Tapped Privacy & Abuse Settings Button"];
    [YTViewHelper loadSettingsController:[[YTPrivacySettingsViewController alloc]init]];
}

- (void)showHelp
{
    [[Mixpanel sharedInstance] track:@"Tapped About Us Settings Button"];
    [YTViewHelper loadSettingsController:[[YTHelpSettingsViewController alloc] init]];
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
    if ([[YTAppDelegate current].userInfo[@"provider"] isEqualToString:@"facebook"]) {
        [YTFBHelper presentFeedDialog];
    } else {
        [[YTGPPHelper sharedInstance] presentShareDialog];
    }
    
    [[Mixpanel sharedInstance] track:@"Tapped Share Button"];
}

@end
