//
//  YTHelpSettingsViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <BITHockeyManager.h>
#import <Mixpanel.h>

#import "YTHelpSettingsViewController.h"
#import "YTViewHelper.h"
#import "YTConfig.h"
#import "YTWebViewController.h"
#import "YTApiHelper.h"
#import "YTHelper.h"

@interface YTHelpSettingsViewController ()

@end

@implementation YTHelpSettingsViewController

# pragma mark UIViewController methods

- (void)viewDidLoad
{
    self.title = NSLocalizedString(@"Help & About Us", nil);

    
    self.tableData = @[
//        @[
//            @[@"", NSLocalizedString(@"Help", nil), @"showHelp"]
//        ],
        @[
            @[@"", NSLocalizedString(@"Update Backdoor", nil), @"showUpdate"],
//            @[@"", NSLocalizedString(@"Licenses", nil), @"showLicenses"],
            @[@"", NSLocalizedString(@"Legal", nil), @"showLegal"],
            @[@"", NSLocalizedString(@"About Us", nil), @"showAbout"]
        ]
    ];
    
    [super viewDidLoad];
}

- (void)showHelp
{
    [self openURL:CONFIG_HELP_HELP_URL title:NSLocalizedString(@"Help", nil)];
}

- (void)showUpdate
{
    if ([YTHelper appStoreEnvironment] || [YTHelper simulatedEnvironment]) {
        [YTApiHelper checkUpdates];
    } else {
        BITHockeyManager *manager = [BITHockeyManager sharedHockeyManager];
        [manager.updateManager showUpdateView];
    }

    //[self openURL:CONFIG_HELP_UPDATE_URL title:NSLocalizedString(@"Update Backdoor", nil)];
}

- (void)showLicenses
{
    [self openURL:CONFIG_HELP_LICENSES_URL title:NSLocalizedString(@"Licenses", nil)];
}

- (void)showLegal
{
    [self openURL:CONFIG_HELP_LEGAL_URL title:NSLocalizedString(@"Legal", nil)];
}

- (void)showAbout
{
    [self openURL:CONFIG_HELP_ABOUT_URL title:NSLocalizedString(@"About Us", nil)];
}


@end
