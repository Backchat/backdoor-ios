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
#import "YTGabs.h"
#import "YTConfig.h"
#import "YTInviteFriendViewController.h"

#define SECTION_FEATURED 0
#define SECTION_GABS 1
#define SECTION_FRIENDS 2
#define SECTION_MORE 3
#define SECTION_INVITE 4
#define SECTION_SHARE 5
#define SECTION_CLUES 6
#define SECTION_COUNT 7

@interface YTMainViewController ()
@property (nonatomic, retain) YTFriends* friends;
@property (nonatomic, retain) YTFriends* featuredUsers;
@property (nonatomic, retain) YTGabs* gabs;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UITapGestureRecognizer* tapTableGesture;
@property (assign, nonatomic) BOOL visible;

- (void)refreshWasRequested;
- (void)composeButtonWasClicked;
- (void)doRefreshFromServer;
@end

@implementation YTMainViewController

# pragma mark Custom methods

- (void)refreshWasRequested
{
    [self doRefreshFromServer];
}

- (void)refresh
{
    self.gabs = [[YTGabs alloc] initWithSearchString:self.searchBar.text];
    self.friends = [[YTFriends alloc] initWithSearchStringRandomized:@""];
    self.featuredUsers = [[YTFriends alloc] initWithFeaturedUsers];
    [self.tableView reloadData];
}

- (void)doRefreshFromServer
{
    [[AFHTTPClient clientWithBaseURL:[YTApiHelper baseUrl]]
     enqueueBatchOfHTTPRequestOperations:@[[YTGabs updateGabNetworkingOperation],
     [YTFriends updateFriendsOfTypeNetworkingOperation:YTFriendType],
     [YTFriends updateFriendsOfTypeNetworkingOperation:YTFeaturedFriendType]]
     progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
     } completionBlock:^(NSArray *operations) {
         [self.refreshControl endRefreshing];
     }];
}

- (void)composeButtonWasClicked
{
    [[Mixpanel sharedInstance] track:@"Tapped Compose Button"];
    
    [self.searchBar resignFirstResponder];
    
    YTNewGabViewController *c = [YTNewGabViewController new];
    [[YTAppDelegate current].navController pushViewController:c animated:YES];
}

#pragma mark UIViewController methods


- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];

    self.visible = TRUE;
    
    [super viewWillAppear:animated];
    
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated

{
    [super viewWillDisappear:animated];
    self.visible = false;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    /* this actually hits endpoints, as opposed to refreshLocally */
    [self doRefreshFromServer];

    if(YTAppDelegate.current.currentUser.newUser || CONFIG_DEBUG_TOUR) {
        YTAppDelegate.current.currentUser.newUser = FALSE;
        [YTTourViewController show];
    }
    
    
}

- (void)setupNavBar
{
    UIImage* invIcon = [YTHelper imageNamed:@"invite-nav-bar-icon"];
    UIImage* settingsImage = [YTHelper imageNamed:@"settings"];
    if([YTHelper isV7]) {
        settingsImage = [settingsImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        invIcon = [invIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    self.navigationItem.leftBarButtonItems = @[
                                               [[UIBarButtonItem alloc] initWithImage:settingsImage
                                                                                style:UIBarButtonItemStyleBordered target:[YTViewHelper class] action:@selector(showSettings)],
                                               [[UIBarButtonItem alloc] initWithImage:invIcon
                                                                                style:UIBarButtonItemStyleBordered target:self action:@selector(showInvite)],
                                                ];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeButtonWasClicked)];
    
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"Messages", nil);
    
    if(![YTHelper isV7]) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Messages", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
    }
}

- (void)showInvite
{
    [[Mixpanel sharedInstance] track:@"Tapped Main View / Invite Friends"];
    [[YTAppDelegate current].navController pushViewController:[YTInviteFriendViewController new] animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupNavBar];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.searchBar = [UISearchBar new];
    [self.searchBar sizeToFit];
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [YTHelper imageNamed:@"navbar3"];
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.tableFooterView = [UIView new];
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshWasRequested) forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[YTHelper imageNamed:@"navbartitle4"]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFriends:)
                                                 name:YTFriendNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFeaturedFriends:)
                                                 name:YTFeaturedFriendNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGabs:)
                                                 name:YTGabsUpdatedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAGab:)
                                                 name:YTGabUpdated object:nil];

    //the other actions on gabs happen while on other pages: this is an assumption that will change
    //if SPLITCODE is on again...
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appActivated:) name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    self.tableView.contentOffset = CGPointMake(0, self.searchBar.frame.size.height);
    
    self.tapTableGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                   action:@selector(cancelSearch:)];
    [self.tapTableGesture setNumberOfTapsRequired:1];
    self.tapTableGesture.enabled = false;
    [self.tableView addGestureRecognizer: self.tapTableGesture];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)appActivated:(NSNotification*)note
{
    if(self.visible)
        [self doRefreshFromServer];
}

- (void)cancelSearch:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([recognizer.view isKindOfClass: [UITableView class]]) {
            [self.searchBar resignFirstResponder];
        }
    }
}

- (void)updateGabs:(NSNotification*)note
{
    self.gabs = [[YTGabs alloc] initWithSearchString:self.searchBar.text];
    [self.tableView reloadData];
    if(note)
        [self.refreshControl endRefreshing];
}

- (void)updateAGab:(NSNotification*)note
{
    //we only really care if a gab was updated and we're visible:
    if(self.visible) {
        //a gab might have been created, or the name changed, etc.
        self.gabs = [[YTGabs alloc] initWithSearchString:self.searchBar.text];
        [self.tableView reloadData];
    }
}

- (void)updateFriends:(NSNotification*)note
{
    self.friends = [[YTFriends alloc] initWithSearchStringRandomized:@""];
    [self.tableView reloadData];
}

- (void)updateFeaturedFriends:(NSNotification*)note
{
    self.featuredUsers = [[YTFriends alloc] initWithFeaturedUsers];
    [self.tableView reloadData];
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
        case SECTION_INVITE: return 1;
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
    return [self.gabs count];
}

- (NSInteger)numberOfFriendRows
{
    if ([YTGabs totalGabCount] >= CONFIG_MAX_CONVERSATION_COUNT_FOR_GHOST_FRIENDS) {
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
    if ([YTGabs totalGabCount] >= CONFIG_MAX_CONVERSATION_COUNT_FOR_GHOST_FRIENDS) {
        return 0;
    }
    
    if(self.friends.count > CONFIG_GHOST_FRIEND_COUNT)
        return 1;
    
    return 0;
}

- (NSInteger)numberOfShareRows
{
    if ([YTGabs totalGabCount] >= CONFIG_MAX_CONVERSATION_COUNT_FOR_GHOST_FRIENDS) {
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
        case SECTION_INVITE: return [[YTMainViewHelper sharedInstance] cellForInvite:tableView];
        case SECTION_GABS: return [self tableView:tableView cellForGabAtRow:indexPath.row];
        case SECTION_FRIENDS: return [self tableView:tableView cellForFriendAtRow:indexPath.row];
        case SECTION_MORE: return [self tableView:tableView cellForMoreAtRow:indexPath.row];
        case SECTION_SHARE: return [[YTMainViewHelper sharedInstance] cellForShare:tableView];
        case SECTION_CLUES: return [self tableView:tableView cellForCluesAtRow:indexPath.row];
        case SECTION_FEATURED: return [self tableView:tableView cellForUserAtRow:indexPath.row];
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForGabAtRow:(NSInteger)row
{
    YTGab *object = [self.gabs gabAtIndex:row];
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithGab:object andTableView:tableView];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUser:(YTFriend*)user
{
    NSString *title = user.name;
    bool featured = !user.isFriend;

    NSString *subtitle = NSLocalizedString(@"Tap me to start a new conversation.", nil);
    NSString *time = featured ? NSLocalizedString(@"Featured", nil) : @"";
    NSString *image = featured ? @"star2" : nil;

    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time
                                                                            image:image
                                                                           avatar:user.avatarUrl
                                                                 placeHolderImage:[YTHelper imageNamed:@"avatar6"]
                                                                  backgroundColor:[UIColor whiteColor]];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForFriendAtRow:(NSInteger)row
{
    YTFriend* f = [self.friends friendAtIndex:row];

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
    return [self tableView:tableView cellForUser:c];
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
                                                                 backgroundColor:[UIColor whiteColor]];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForMoreAtRow:(NSInteger)row
{
    NSString *title = NSLocalizedString(@"Show More", nil);
    NSString *subtitle = NSLocalizedString(@"Show all of your Backchat friends.", nil);
    NSString *time = @"";
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time image:@""
                                                                          avatar:@"more2" placeHolderImage:nil
                                                                 backgroundColor:nil];

    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
}

# pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == SECTION_GABS) {
        YTGab *gab = [self.gabs gabAtIndex:indexPath.row];
        [YTViewHelper showGab:gab animated:YES];
    }
    else if (indexPath.section == SECTION_FRIENDS) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Friend Item"];
        [YTViewHelper showGabWithFriend:[self.friends friendAtIndex:indexPath.row] animated:YES];
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
        [YTViewHelper showGabWithFriend:[self.featuredUsers friendAtIndex:indexPath.row] animated:YES];
    }
    else if(indexPath.section == SECTION_INVITE) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Invite Friends"];
        [[YTAppDelegate current].navController pushViewController:[YTInviteFriendViewController new] animated:YES];
    }

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
    if (indexPath.section == SECTION_GABS) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    [YTGabs deleteGab:[self.gabs gabAtIndex:indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

#pragma mark UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[Mixpanel sharedInstance] track:@"Used Thread Search Bar"];
    self.gabs = [[YTGabs alloc] initWithSearchString:searchText];
    //self.friends = [[YTFriends alloc] initWithSearchString:searchText];
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.tapTableGesture.enabled = true;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.tapTableGesture.enabled = false;
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
