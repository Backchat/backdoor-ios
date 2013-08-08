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
#import "YTSocialHelper.h"
#import "YTMainViewHelper.h"
#import "YTHelper.h"
#import "YTFriends.h"
#import "YTFBHelper.h"
#import "YTInviteContactViewController.h"

@interface YTNewGabViewController ()
@property (strong, nonatomic) YTFriends* friends;
@property (strong, nonatomic) YTContacts* contacts;
@property (strong, nonatomic) YTContacts* filteredContacts;

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIActivityIndicatorView* spinner;
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
    
    self.friends = [[YTFriends alloc] init];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.sectionHeaderHeight = 0;
    
    self.searchBar = [UISearchBar new];
    [self.searchBar sizeToFit];
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [YTHelper imageNamed:@"navbar3"];
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = [UIColor clearColor];

    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonWasClicked)];
    
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];

    [self.view addSubview:self.tableView];
    
    self.title = NSLocalizedString(@"New Message", nil);
    
    self.contacts = nil;

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
               UIActivityIndicatorViewStyleGray];

    [YTFBHelper fetchFriends:^(YTContacts *c) {
        self.contacts = [[YTContacts alloc] initWithContacts:c excludingFriends:[[YTFriends alloc] init]];
        self.filteredContacts = [[YTContacts alloc] initWithContacts:self.contacts withFilter:self.searchBar.text];
        
        
        [self.tableView reloadData];
    }];
}


- (void)cancelButtonWasClicked
{
    [[Mixpanel sharedInstance] track:@"Tapped New Gab View / Cancel Button"];

    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case 0: return self.friends.count;
        case 1:
            if(self.contacts)
                return self.filteredContacts.count;
            else
                return 1;
        case 2: return 1;
        default: return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case 0: return [self tableView:tableView cellForUserAtIndexPath:indexPath];
        case 1: return [self tableView:tableView cellForContactAtIndexPath:indexPath];
        case 2: return [self tableView:tableView cellForShareAtRow:0];
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForContactAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = @"";
    NSString *subtitle = @"";
    NSString *time = @"";
    NSString* avatarUrl = nil;
    UIImage* placeHolder =nil;

    if(self.contacts) {
        YTContact* c = [self.filteredContacts contactAtIndex:indexPath.row];
        title = c.name;
        subtitle = NSLocalizedString(@"Send anonymous text to invite", nil);
        time = c.localizedType;
        placeHolder = [YTHelper imageNamed:@"avatar6"];
        avatarUrl = c.avatarUrl;
    }
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time
                                                                           image:nil
                                                                          avatar:avatarUrl
                                                                placeHolderImage:placeHolder
                             backgroundColor:[UIColor colorWithRed:234.0/255.0 green:242.0/255.0 blue:246.0/255.0 alpha:1.0]];

    if(!self.contacts) {
        int width = 32, height = 32;
        int rowHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
        self.spinner.frame = CGRectMake(
                                   (self.view.frame.size.width - width) / 2,
                                   (rowHeight - height)/2,
                                   width, height);
        [self.spinner removeFromSuperview];
        [cell addSubview:self.spinner];
        [self.spinner startAnimating];        
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUserAtIndexPath:(NSIndexPath *)indexPath
{
    YTFriend* friend = [self.friends friendAtIndex:indexPath.row];
    NSString *title = friend.name;
    NSString *subtitle = NSLocalizedString(@"Tap me to start a new conversation.", nil);
    NSString *time = @"";
    NSString* image = friend.isFriend ? nil : @"star2";
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time
                                                                           image:image
                                                                          avatar:friend.avatarUrl
								placeHolderImage:[YTHelper imageNamed:@"avatar6"]
								 backgroundColor:nil];
        
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForShareAtRow:(NSInteger)row
{
    NSString *title = NSLocalizedString(@"Share", nil);
    NSString *subtitle = NSLocalizedString(@"Tap me to get more BD friends.", nil);
    NSString *time = @"";
    NSString *image = @"https://s3.amazonaws.com/backdoor_images/icon_114x114.png";
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView
                                                                           title:title
                                                                        subtitle:subtitle
                                                                            time:time
                                                                           image:nil
                                                                          avatar:image
                                                                placeHolderImage:nil
                                                                 backgroundColor:nil];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch(indexPath.section) {
        case 0:
            [[Mixpanel sharedInstance] track:@"Tapped New Gab View / Friend Item"];
            [YTViewHelper showGabWithFriend:[self.friends friendAtIndex:indexPath.row]];
            return;
        case 1:
        {
            [[Mixpanel sharedInstance] track:@"Tapped New Gab View / Invite FB Friend Item"];
            YTInviteContactViewController* invite = [YTInviteContactViewController new];
            invite.contact = [self.filteredContacts contactAtIndex:indexPath.row];
            [[YTAppDelegate current].navController pushViewController:invite animated:YES];
            return;
        }
        case 2:
            [[Mixpanel sharedInstance] track:@"Tapped New Gab View / Share Item"];
            [[YTSocialHelper sharedInstance] presentShareDialog];
            return;
        default:
            return;
    }
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[Mixpanel sharedInstance] track:@"Used New Gab View / Search Bar"];
    self.friends = [[YTFriends alloc] initWithSearchString:searchText];
    self.filteredContacts = [[YTContacts alloc] initWithContacts:self.contacts withFilter:searchText];
    [self.tableView reloadData];
}



@end
