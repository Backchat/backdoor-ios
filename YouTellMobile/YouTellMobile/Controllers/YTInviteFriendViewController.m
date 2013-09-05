//
//  YTInviteFriendViewController.m
//  Backdoor
//
//  Created by Lin Xu on 8/29/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTInviteFriendViewController.h"
#import "YTContacts.h"
#import "YTFBHelper.h"
#import "YTHelper.h"
#import "YTMainViewHelper.h"
#import "YTInviteContactViewController.h"
#import "YTFriends.h"
#import "YTAddressBookHelper.h"
#import "YTInviteContactComposeViewController.h"

@interface YTInviteFriendViewController ()
@property (retain, nonatomic) YTContacts* contacts;
@property (retain, nonatomic) YTContacts* filteredContacts;
@end

@implementation YTInviteFriendViewController

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
    self.title = NSLocalizedString(@"Invite Friends", nil);
    /* we use contacts for now, and don't try to filter out the people we know.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendsUpdated:)
                                                 name:YTFriendNotification object:nil];*/
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [YTAddressBookHelper fetchContacts:^(YTContacts *c) {
        self.contacts = c;
        self.filteredContacts = [[YTContacts alloc] initWithContacts:self.contacts withFilter:self.searchBar.text];
        [self.tableView reloadData];

    }];
    //[YTFriends updateFriendsOfType:YTFriendType];
}

- (void) friendsUpdated:(NSNotification*)note
{
    //currently unused
    [YTFBHelper fetchFriends:^(YTContacts *c) {
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = @"";
    NSString *subtitle = @"";
    NSString *time = @"";
    NSString* avatarUrl = nil;
    UIImage* placeHolder =nil;
    
    YTContact* c = [self.filteredContacts contactAtIndex:indexPath.row];
    title = c.name;
    subtitle = c.phone_number; //NSLocalizedString(@"Send text to invite", nil);
    time = c.localizedType;
    placeHolder = [YTHelper imageNamed:@"avatar6"];
    avatarUrl = c.avatarUrl;
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time
                                                                           image:nil
                                                                          avatar:avatarUrl
                                                                placeHolderImage:placeHolder
                                                                 backgroundColor:[UIColor colorWithRed:234.0/255.0 green:242.0/255.0 blue:246.0/255.0 alpha:1.0]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.filteredContacts)
        return self.filteredContacts.count;
    else
        return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /* everyone now has a phone number always since we use contacts.
    YTInviteContactViewController* view = [YTInviteContactViewController new];
    view.contact = [self.filteredContacts contactAtIndex:indexPath.row];
    [self.navigationController pushViewController:view animated:YES];*/
    YTInviteContactComposeViewController* compose = [YTInviteContactComposeViewController new];
    compose.contact = [self.filteredContacts contactAtIndex:indexPath.row];
    [self.navigationController pushViewController:compose animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.filteredContacts = [[YTContacts alloc] initWithContacts:self.contacts withFilter:searchText];
    [self.tableView reloadData];
}

@end
