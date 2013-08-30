//
//  YTNewGabViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTNewGabViewController.h"

#import <Mixpanel.h>

#import "YTModelHelper.h"
#import "YTMainViewHelper.h"
#import "YTHelper.h"
#import "YTFriends.h"
#import "YTSocialHelper.h"
#import "YTInviteFriendViewController.h"

@interface YTNewGabViewController ()
@property (strong, nonatomic) YTFriends* friends;
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
        
    self.title = NSLocalizedString(@"New Message", nil);
    
    self.friends = [[YTFriends alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFriends:)
                                                 name:YTFriendNotification object:nil];
}

- (void)refreshFriends:(NSNotification*)note
{
    self.friends = [[YTFriends alloc] initWithSearchString:self.searchBar.text];
        
    [self.tableView reloadData];
}

- (void)cancelButtonWasClicked
{
    [[Mixpanel sharedInstance] track:@"Tapped New Gab View / Cancel Button"];
    [super cancelButtonWasClicked];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case 0:
            return self.friends.count;
        case 1:
        case 2:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case 0:
            return [self tableView:tableView cellForUserAtIndexPath:indexPath];
        case 1:
            return [[YTMainViewHelper sharedInstance] cellForInvite:tableView];
        case 2:            
            return [[YTMainViewHelper sharedInstance] cellForShare:tableView];
        default:
            return nil;
    }
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
								 backgroundColor:[UIColor whiteColor]];
        
    return cell;
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
            [YTViewHelper showGabWithFriend:[self.friends friendAtIndex:indexPath.row] animated:YES];
            return;
        case 1:
            [[Mixpanel sharedInstance] track: @"Tapped New Gab View / Invite Item"];
            [self.navigationController pushViewController:[YTInviteFriendViewController new] animated:YES];
            return;
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
    [self refreshFriends:nil];
}

@end
