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
#import "YTContactHelper.h"
#import "YTModelHelper.h"
#import "YTApiHelper.h"
#import "YTViewHelper.h"
#import "YTNewGabViewController.h"
#import "YTConfig.h"
#import "YTGPPHelper.h"
#import "YTSocialHelper.h"
#import "YTMainViewHelper.h"
#import "YTTourViewController.h"


#define SECTION_GABS 0
#define SECTION_FRIENDS 1
#define SECTION_MORE 2
#define SECTION_SHARE 3
#define SECTION_FEATURED 4
#define SECTION_COUNT 5

@interface YTMainViewController ()
@property (nonatomic, retain) NSMutableArray* currentFeaturedUsers;
@property (nonatomic, retain) NSMutableArray* currentFilteredUsers;
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
    [YTApiHelper getFeaturedUsers];
    [YTApiHelper getFriends];
}

- (void)composeButtonWasClicked
{
    [[Mixpanel sharedInstance] track:@"Tapped Compose Button"];
    
    [self.searchBar resignFirstResponder];
    
    YTNewGabViewController *c = [YTNewGabViewController new];
    [[YTAppDelegate current].navController pushViewController:c animated:YES];
    //[YTViewHelper showGab];
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
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshWasRequested) forControlEvents:UIControlEventValueChanged];
    
   // self.title = NSLocalizedString(@"Backdoor", nil);
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[YTHelper imageNamed:@"navbartitle4"]];
    self.view.backgroundColor = [UIColor whiteColor];

    self.currentFeaturedUsers = [[NSMutableArray alloc] init];
    self.currentFilteredUsers = [[NSMutableArray alloc] init];

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
    
    NSInteger count = [YTContactHelper sharedInstance].filteredRandomizedFriends.count;
    NSInteger ret = MIN(count, CONFIG_GHOST_FRIEND_COUNT);
     
    return ret;
}

- (NSInteger)numberOfFeaturedRows
{
    return [[YTAppDelegate current].featuredUsers count];
}

- (NSInteger)numberOfMoreRows
{
    if ([YTModelHelper gabCountWithFilter:@""] >= CONFIG_MAX_CONVERSATION_COUNT_FOR_GHOST_FRIENDS) {
        return 0;
    }
    
    if ([YTContactHelper sharedInstance].randomizedFriends.count > [self numberOfFriendRows]) {
        return 1;
    }
    
    return 0;
}

- (NSInteger)numberOfShareRows
{
    if ([YTModelHelper gabCountWithFilter:@""] >= CONFIG_MAX_CONVERSATION_COUNT_FOR_GHOST_FRIENDS) {
        return 0;
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case SECTION_GABS: return [self tableView:tableView cellForGabAtRow:indexPath.row];
        case SECTION_FRIENDS: return [self tableView:tableView cellForFriendAtRow:indexPath.row];
        case SECTION_MORE: return [self tableView:tableView cellForMoreAtRow:indexPath.row];
        case SECTION_SHARE: return [self tableView:tableView cellForShareAtRow:indexPath.row];
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

    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time image:image];

    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];
    [avatarView setImageWithURL:[NSURL URLWithString:[object valueForKey:@"related_avatar"]] placeholderImage:[YTHelper imageNamed:@"avatar6"] options:SDWebImageRefreshCached];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUser:(NSDictionary*)user featured:(BOOL)featured
{
    NSString *title = user[@"name"];
    NSString *subtitle = NSLocalizedString(@"Tap me to start a new conversation.", nil);
    NSString *time = featured ? NSLocalizedString(@"Featured", nil) : @"";
    NSString *image = featured ? @"star2" : nil;
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time image:image];
    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];

    if ([user[@"type"] isEqualToString:@"facebook"]) {
        NSString *urls = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", user[@"value"]];
        [avatarView setImageWithURL:[NSURL URLWithString:urls] placeholderImage:[YTHelper imageNamed:@"avatar6"] options:SDWebImageRefreshCached];
    } else if ([user[@"type"] isEqualToString:@"gpp"]) {
        NSString *urls = [NSString stringWithFormat:@"https://profiles.google.com/s2/photos/profile/%@?sz=50", user[@"value"]];
        [avatarView setImageWithURL:[NSURL URLWithString:urls] placeholderImage:[YTHelper imageNamed:@"avatar6"] options:SDWebImageRefreshCached];
    } else {
        [avatarView setImage:nil];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForFriendAtRow:(NSInteger)row
{
    NSDictionary *friendData = [YTContactHelper sharedInstance].filteredRandomizedFriends[row];
    NSDictionary *friend = [[YTContactHelper sharedInstance] findContactWithType:friendData[@"type"] value:friendData[@"value"]];
    UITableViewCell *cell = [self tableView:tableView cellForUser:friend featured:NO];
    
    for (UIView *view in cell.contentView.subviews) {
        view.alpha = 0.6;
        [view setNeedsDisplay];
    }
    

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUserAtRow:(NSInteger)row
{
    NSDictionary *user = [YTAppDelegate current].featuredUsers[row];
    return [self tableView:tableView cellForUser:user featured:YES];
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
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForMoreAtRow:(NSInteger)row
{
    NSString *title = NSLocalizedString(@"Show More", nil);
    NSString *subtitle = NSLocalizedString(@"Show all of your Backdoor friends.", nil);
    NSString *time = @"";
    NSString *image = nil;
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time image:image];
    
    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];
    [avatarView setImage:[UIImage imageNamed:@"more2"]];
    

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
        NSDictionary *friendData = [YTContactHelper sharedInstance].filteredRandomizedFriends[indexPath.row];
        NSDictionary *friend = [[YTContactHelper sharedInstance] findContactWithType:friendData[@"type"] value:friendData[@"value"]];
        [YTViewHelper showGabWithReceiver:friend];
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
    else if (indexPath.section == SECTION_FEATURED) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Featured Users Item"];
        NSDictionary *user = [YTAppDelegate current].featuredUsers[indexPath.row];
        [YTViewHelper showGabWithReceiver:user];
    }
    
    return nil;
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
        [[YTContactHelper sharedInstance] filterRandomizedFriends];
        // [tableView reloadData];   Called by filterRandomizedFriends
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
    [self reloadData];
}
     
- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
