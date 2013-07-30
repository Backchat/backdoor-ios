//
//  YTMainViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>

#import <UIImageView+WebCache.h>
#import <Mixpanel.h>

#import "YTAppDelegate.h"
#import "YTMainViewController.h"
#import "YTHelper.h"
#import "YTModelHelper.h"
#import "YTApiHelper.h"
#import "YTViewHelper.h"
#import "YTNewGabViewController.h"
#import "YTConfig.h"
#import "YTGPPHelper.h"
#import "YTSocialHelper.h"
#import "YTMainViewHelper.h"
#import "YTTourViewController.h"
#import "YTFriends.h"

#define SECTION_GABS 0
#define SECTION_FRIENDS 1
#define SECTION_MORE 2
#define SECTION_SHARE 3
#define SECTION_CLUES 4
#define SECTION_FEATURED 5
#define SECTION_COUNT 6

@interface YTMainViewController ()
@property (nonatomic, retain) YTFriends* friends;
@property (nonatomic, retain) YTFriends* featuredUsers;
@end

@implementation YTMainViewController

# pragma mark Custom methods

- (void)refreshWasRequested
{
    [[Mixpanel sharedInstance] track:@"Dragged Refresh Control"];
    [self doRefresh];
}

- (void)doRefresh
{
    [YTApiHelper syncGabs];
    [YTApiHelper getFeaturedUsers:^() {
        self.featuredUsers = [[YTFriends alloc] initWithFeaturedUsers];
        [self reloadData];
    }];
    [YTApiHelper getFriends:^() {
        self.friends = [[YTFriends alloc] initWithSearchStringRandomized:@""];
        [self reloadData];
    }];
}

- (void)composeButtonWasClicked
{
    [[Mixpanel sharedInstance] track:@"Tapped Compose Button"];
    
    [self.searchBar resignFirstResponder];
    
    YTNewGabViewController *c = [YTNewGabViewController new];
    [[YTAppDelegate current].navController pushViewController:c animated:YES];
}

- (void)reloadData
{

    [self.tableView reloadData];
}


#pragma mark UIViewController methods

- (void)viewDidAppear:(BOOL)animated
{
    [self doRefresh];
    [super viewDidAppear:animated];
    if([YTApiHelper isNewUser]) {
        [YTApiHelper setNewUser:FALSE];
        [YTTourViewController show];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[YTHelper imageNamed:@"settings"] style:UIBarButtonItemStyleBordered target:[YTViewHelper class] action:@selector(showSettings)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeButtonWasClicked)];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Messages", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
    
    self.searchBar = [UISearchBar new];
    [self.searchBar sizeToFit];
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [YTHelper imageNamed:@"navbar3"];
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.tableFooterView = [UIView new];
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshWasRequested) forControlEvents:UIControlEventValueChanged];
    
   // self.title = NSLocalizedString(@"Backdoor", nil);
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[YTHelper imageNamed:@"navbartitle4"]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case SECTION_GABS: return [self numberOfGabRows];
        case SECTION_FRIENDS: return [self numberOfFriendRows];
        case SECTION_MORE: return [self numberOfMoreRows];
        case SECTION_SHARE: return [self numberOfShareRows];
        case SECTION_CLUES: return [self numberOfCluesRows];
        case SECTION_FEATURED: return [self numberOfFeaturedRows];
        default: return 0;
    }
}

- (NSInteger)numberOfGabRows
{
    return [YTModelHelper gabCountWithFilter:self.searchBar.text];
}

- (NSInteger)numberOfFriendRows
{
    if ([YTModelHelper gabCountWithFilter:@""] >= CONFIG_MAX_CONVERSATION_COUNT_FOR_GHOST_FRIENDS) {
        return 0;
    }
    
    NSInteger count = self.friends.count;
    NSInteger ret = MIN(count, CONFIG_GHOST_FRIEND_COUNT);
     
    return ret;
}

- (NSInteger)numberOfFeaturedRows
{
    return self.featuredUsers.count;
}

- (NSInteger)numberOfMoreRows
{
    if ([YTModelHelper gabCountWithFilter:@""] >= CONFIG_MAX_CONVERSATION_COUNT_FOR_GHOST_FRIENDS) {
        return 0;
    }
    
    if(self.friends.count > CONFIG_GHOST_FRIEND_COUNT)
        return 1;
    
    return 0;
}

- (NSInteger)numberOfShareRows
{
    if ([YTModelHelper gabCountWithFilter:@""] >= CONFIG_MAX_CONVERSATION_COUNT_FOR_GHOST_FRIENDS) {
        return 0;
    }
    
    return 1;
}

- (NSInteger)numberOfCluesRows
{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case SECTION_GABS: return [self tableView:tableView cellForGabAtRow:indexPath.row];
        case SECTION_FRIENDS: return [self tableView:tableView cellForFriendAtRow:indexPath.row];
        case SECTION_MORE: return [self tableView:tableView cellForMoreAtRow:indexPath.row];
        case SECTION_SHARE: return [self tableView:tableView cellForShareAtRow:indexPath.row];
        case SECTION_CLUES: return [self tableView:tableView cellForCluesAtRow:indexPath.row];

        case SECTION_FEATURED: return [self tableView:tableView cellForUserAtRow:indexPath.row];
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForGabAtRow:(NSInteger)row
{
    NSManagedObject *object = [YTModelHelper gabForRow:row  filter:self.searchBar.text];

    BOOL read = [[object valueForKey:@"unread_count"] isEqualToNumber:@0];
    NSString *title = [YTModelHelper userNameForGab:object];
    NSString *subtitle = [object valueForKey:@"content_summary"];
    NSString *time = [YTHelper formatDate:[object valueForKey:@"updated_at"]];
    NSString *image = read ? nil : @"newgab2";
    NSString* avatar = (NSString*)[object valueForKey:@"related_avatar"];
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time
                                                                           image:image
                                                                          avatar:avatar
                                                                placeHolderImage:[YTHelper imageNamed:@"avatar6"]
                                                                 backgroundColor:nil];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUser:(YTFriend*)user
{
    NSLog(@"%@ %@ %@", tableView, user, user.isFault ? @"YES" : @"NO");
    NSString *title = user.name;
    bool featured = !user.isFriend;
    NSLog(@"%@ %@ %@", tableView, user, user.isFault ? @"YES" : @"NO");

    NSString *subtitle = NSLocalizedString(@"Tap me to start a new conversation.", nil);
    NSString *time = featured ? NSLocalizedString(@"Featured", nil) : @"";
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time
                                                                           image:@""
                                                                          avatar:user.avatarUrl
                                                                placeHolderImage:[YTHelper imageNamed:@"avatar6"]
                                                                 backgroundColor:nil];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForFriendAtRow:(NSInteger)row
{
    YTFriend* f = [self.friends friendAtIndex:row];
    NSLog(@"%@", f.name);

    UITableViewCell *cell = [self tableView:tableView cellForUser:f];
    
    for (UIView *view in cell.contentView.subviews) {
        view.alpha = 0.6;
        [view setNeedsDisplay];
    }
    

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUserAtRow:(NSInteger)row
{
    YTFriend* c = [self.featuredUsers friendAtIndex:row];
    NSLog(@"%@", c.name);
    return [self tableView:tableView cellForUser:c];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForShareAtRow:(NSInteger)row
{
    NSString *title = NSLocalizedString(@"Share", nil);
    NSString *subtitle = NSLocalizedString(@"Tap me to get more BD friends.", nil);
    NSString *time = @"";
    NSString *image = @"https://s3.amazonaws.com/backdoor_images/icon_114x114.png";;
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time image:@""
                                                                          avatar:image placeHolderImage:nil
                                                                 backgroundColor:nil];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForCluesAtRow:(NSInteger)row
{
    NSString *title = NSLocalizedString(@"Get Clues", nil);
    NSString *subtitle = NSLocalizedString(@"Tap me to get more clues.", nil);
    NSString *time = @"";
    NSString *image = nil;
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView
                                                                           title:title subtitle:subtitle time:time
                                                                           image:image
                                                                          avatar:@"get_clues_btn" placeHolderImage:nil
                                                                 backgroundColor:nil];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForMoreAtRow:(NSInteger)row
{
    NSString *title = NSLocalizedString(@"Show More", nil);
    NSString *subtitle = NSLocalizedString(@"Show all of your Backdoor friends.", nil);
    NSString *time = @"";
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time image:@""
                                                                          avatar:@"more2" placeHolderImage:nil
                                                                 backgroundColor:nil];

    return cell;
}

# pragma mark UITableViewDelegate methods

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
    
    if (indexPath.section == SECTION_GABS) {
        NSManagedObject *object = [YTModelHelper gabForRow:indexPath.row  filter:self.searchBar.text];
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Thread Item"];
        self.selectedGabId = [object valueForKey:@"id"];
        [YTViewHelper showGabWithId:self.selectedGabId];
    }
    else if (indexPath.section == SECTION_FRIENDS) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Friend Item"];
        [YTViewHelper showGabWithFriend:[self.friends friendAtIndex:indexPath.row]];
    }    
    else if (indexPath.section == SECTION_MORE) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / More Item"];
        [self.searchBar resignFirstResponder];
        
        YTNewGabViewController *c = [YTNewGabViewController new];
        [[YTAppDelegate current].navController pushViewController:c animated:YES];
    }
    else if (indexPath.section == SECTION_SHARE) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Share Item"];
        [[YTSocialHelper sharedInstance] presentShareDialog];
    }
    else if (indexPath.section == SECTION_CLUES) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Clues Item"];
        if(![YTAppDelegate current].storeHelper) {
            [YTAppDelegate current].storeHelper = [YTStoreHelper new];
        }
        [[YTAppDelegate current].storeHelper showFromBarButtonItem:nil];
    }
    else if (indexPath.section == SECTION_FEATURED) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Featured Users Item"];
        [YTViewHelper showGabWithFriend:[self.featuredUsers friendAtIndex:indexPath.row]];
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_GABS) {
        return YES;
    } else {
        return NO;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    NSManagedObject *object = [YTModelHelper gabForRow:indexPath.row filter:self.searchBar.text];
    [YTApiHelper deleteGab:[object valueForKey:@"id"] success:^(id JSON) {
        [tableView reloadData];
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

#pragma mark UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[Mixpanel sharedInstance] track:@"Used Thread Search Bar"];
    //self.friends = [[YTFriends alloc] initWithSearchString:searchText];
    [self reloadData];
}
     
- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
