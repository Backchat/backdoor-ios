//
//  YTNewGabViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTNewGabViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <Mixpanel.h>

#import "YTModelHelper.h"
#import "YTContactHelper.h"
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
    self.tableView.contentOffset = CGPointMake(0, self.searchBar.frame.size.height);

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[Mixpanel sharedInstance] track:@"Tapped New Gab View / Friend Item"];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.searchBar resignFirstResponder];
    
    NSDictionary *contact = self.contacts[indexPath.row];
    [YTViewHelper showGabWithReceiver:contact];
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[Mixpanel sharedInstance] track:@"Used New Gab View / Search Bar"];
    self.contacts = [[YTContactHelper sharedInstance] findContactsFlatWithString:searchText];
    [self.tableView reloadData];
}



@end
