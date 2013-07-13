//
//  YTNewGabViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTNewGabViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <SDWebImage/UIImageView+WebCache.h>
#import <Mixpanel.h>

#import "YTModelHelper.h"
#import "YTContactHelper.h"
#import "YTSocialHelper.h"
#import "YTMainViewHelper.h"
#import "YTHelper.h"

@interface YTNewGabViewController ()

@end

@implementation YTNewGabViewController

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
    
    self.contacts = [[YTContactHelper sharedInstance] findContactsFlatWithString:@""];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.sectionHeaderHeight = 0;
    
    self.searchBar = [UISearchBar new];
    [self.searchBar sizeToFit];
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [YTHelper imageNamed:@"navbar3"];
    self.tableView.tableHeaderView = self.searchBar;

    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonWasClicked)];
    
    [self.view addSubview:self.tableView];
    
    self.title = NSLocalizedString(@"New Message", nil);
}

- (void)cancelButtonWasClicked
{
    [[Mixpanel sharedInstance] track:@"Tapped New Gab View / Cancel Button"];

    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [self tableView:tableView cellForUserAtIndexPath:indexPath];
    }
    
    if (indexPath.section == 1) {
        return [self tableView:tableView cellForShareAtRow:0];
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUserAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *record = self.contacts[indexPath.row];
    NSString *title = record[@"name"];
    NSString *subtitle = NSLocalizedString(@"Tap me to start a new conversation.", nil);
    NSString *image = nil;
    NSString *time = @"";
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time image:image];
    
    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];
    [[YTContactHelper sharedInstance] showAvatarInImageView:avatarView forContact:record];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForShareAtRow:(NSInteger)row
{
    NSString *title = NSLocalizedString(@"Share", nil);
    NSString *subtitle = NSLocalizedString(@"Tap me to get more BD friends.", nil);
    NSString *time = @"";
    NSString *image = nil;
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time image:image];
    
    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];
    
    NSString *url = @"https://s3.amazonaws.com/backdoor_images/icon_114x114.png";
    [avatarView setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageRefreshCached];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        [[Mixpanel sharedInstance] track:@"Tapped New Gab View / Friend Item"];

        [self.searchBar resignFirstResponder];
    
        NSDictionary *contact = self.contacts[indexPath.row];
        [YTViewHelper showGabWithReceiver:contact];
        return;
    }
    
    if (indexPath.section == 1) {
        [[Mixpanel sharedInstance] track:@"Tapped New Gab View / Share Item"];
        [[YTSocialHelper sharedInstance] presentShareDialog];
        return;
    }
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[Mixpanel sharedInstance] track:@"Used New Gab View / Search Bar"];
    self.contacts = [[YTContactHelper sharedInstance] findContactsFlatWithString:searchText];
    [self.tableView reloadData];
}



@end
