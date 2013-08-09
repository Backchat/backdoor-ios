//
//  YTPrivacySettingsViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Mixpanel.h>

#import "YTPrivacySettingsViewController.h"
#import "YTViewHelper.h"
#import "YTConfig.h"
#import "YTAbuseViewController.h"

@interface YTPrivacySettingsViewController ()

@end

@implementation YTPrivacySettingsViewController

# pragma mark UIViewController methods

- (void)viewDidLoad
{
    self.title = NSLocalizedString(@"Privacy & Abuse", nil);
    
    self.tableData = @[
        @[
            @[@"", NSLocalizedString(@"Privacy Policy", nil), @"showPolicy"]
        ], @[
            @[@"", NSLocalizedString(@"Report Abuse", nil), @"showReport"],

        ]
    ];
    
    [super viewDidLoad];
}

- (void)showPolicy
{
    [self openURL:CONFIG_PRIVACY_POLICY_URL title:NSLocalizedString(@"Privacy Policy", nil)];
}

- (void)showReport
{
    [[Mixpanel sharedInstance] track:@"Tapped Report Abuse Button"];
    YTAbuseViewController *c = [[YTAbuseViewController alloc] init];
    [self.navigationController pushViewController:c animated:YES];
    
    //[self openURL:CONFIG_PRIVACY_VIOLATION_URL title:NSLocalizedString(@"Report Abuse", nil)];
}


@end
