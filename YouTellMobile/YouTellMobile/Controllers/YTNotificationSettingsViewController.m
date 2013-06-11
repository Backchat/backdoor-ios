//
//  YTNotificationSettingsViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTNotificationSettingsViewController.h"
#import "YTApiHelper.h"
#import "YTAppDelegate.h"
#import "YTModelHelper.h"
#import "YTNotifHelper.h"


@interface YTNotificationSettingsViewController ()

@end

@implementation YTNotificationSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = NSLocalizedString(@"Notifications", nil);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
//    NSArray *hints = @[NSLocalizedString(@"Play a sound when a new message is received", nil), NSLocalizedString(@"Vibrate the device when a new\nmessage is received", nil), NSLocalizedString(@"Show message preview inside new\nmessage notifications", nil)];
    
    NSArray *hints = @[NSLocalizedString(@"Play a sound when a new message is received", nil), NSLocalizedString(@"Show message preview inside new\nmessage notifications", nil)];
    
//    NSArray *labels = @[NSLocalizedString(@"Sound", nil), NSLocalizedString(@"Vibration", nil), NSLocalizedString(@"Message Preview", nil)];

    NSArray *labels = @[NSLocalizedString(@"Sound", nil), NSLocalizedString(@"Message Preview", nil)];
    
    if (indexPath.row == 1) {
        cell = [self cellForHintWithTableView:tableView];
        UILabel *label = (UILabel*)[cell viewWithTag:10];
        label.text = hints[indexPath.section];
    } else {
        cell = [self cellForSwitchWithTableView:tableView];
        cell.textLabel.text = labels[indexPath.section];
        cell.tag = indexPath.section;
        UISwitch *swtch = (UISwitch*)[cell viewWithTag:10];
        switch (indexPath.section) {
            case 0: swtch.on = [YTNotifHelper soundEnabled]; break;
            //case 1: swtch.on = [YTNotifHelper vibrationEnabled]; break;
            case 1: swtch.on = [[YTAppDelegate current].userInfo[@"settings"][@"message_preview"] boolValue]; break;
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (UITableViewCell *)cellForHintWithTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell_hint"];
    
    if (cell == nil) {
        UILabel *label;
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell_hint"];
        label = [[UILabel alloc] init];
        label.frame = CGRectMake(10, 0, tableView.frame.size.width - 20, 60);
        label.font = [UIFont boldSystemFontOfSize:15];
        
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:130/255.0 green:130/255.0 blue:130/255.0 alpha:1];
        label.numberOfLines = 2;
        label.backgroundColor = [UIColor clearColor];
        label.tag = 10;
        
        [cell addSubview:label];
    }
    
    return cell;
}


- (UITableViewCell *)cellForSwitchWithTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell_switch"];
    

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell_switch"];

        UISwitch *sw = [[UISwitch alloc] init];
        sw.frame = CGRectMake(tableView.frame.size.width - 10 - 79 - 5, 10, 79, 27);
        sw.tag = 10;
        
        [sw addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        [cell addSubview:sw];
    }
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 45;
    } else {
        return 60;
    }
}

- (void)switchValueChanged:(UISwitch*)sender
{
    UITableViewCell *cell = (UITableViewCell*)[sender superview];
    NSNumber *value = [NSNumber numberWithBool:sender.on];
    
    switch(cell.tag) {
        case 0: [YTNotifHelper setSoundEnabled:sender.on]; break;
        //case 1: [YTNotifHelper setVibrationEnabled:sender.on]; break;
        case 1: [YTApiHelper updateSettingsWithKey:@"message_preview" value:value];
    }
}

@end
