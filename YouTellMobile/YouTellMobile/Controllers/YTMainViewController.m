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
#import "YTConfig.h"
#import "YTGPPHelper.h"
#import "YTSocialHelper.h"

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
    [YTApiHelper autoSync:NO];
}

- (void)composeButtonWasClicked
{
    [[Mixpanel sharedInstance] track:@"Tapped Compose Button"];
    [self.searchBar resignFirstResponder];
    [YTViewHelper showGab];
}

- (void)deselectSelectedGab:(BOOL)animated
{
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:animated];
    self.selectedGabId = nil;
}

- (void)reloadData
{
    [self.tableView reloadData];
    
    [self.tableView selectRowAtIndexPath:[YTModelHelper indexPathForGab:self.selectedGabId filter:self.searchBar.text] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (UITableViewCell *)cellWithIdent:(NSString*)ident
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ident];
    
    if (cell) {
        return cell;
    }
    
    if ([ident isEqualToString:@"cell"]) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident];
    } else {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident];
    }
    
    UIImageView *avatarView = [[UIImageView alloc] init];
    avatarView.tag = 5;
    avatarView.layer.cornerRadius = 5;
    avatarView.layer.masksToBounds = YES;
    avatarView.frame = CGRectMake(26, 7, 45, 45);
    [cell.contentView addSubview:avatarView];
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textLabel.font = [UIFont systemFontOfSize:12];
    textLabel.textColor = cell.textLabel.textColor;
    textLabel.tag = 2;
    textLabel.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:textLabel];
    cell.textLabel.textColor = [UIColor clearColor];
    
    if (![ident isEqualToString:@"cell"]) {
        return cell;
    }

    cell.textLabel.font = [UIFont systemFontOfSize:17];
    
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.font = [UIFont systemFontOfSize:12];
    timeLabel.textColor = [UIColor blueColor];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.tag = 1;

    [cell.contentView addSubview:timeLabel];

    UILabel *detTextLabel = [[UILabel alloc] init];
    detTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    detTextLabel.font = [UIFont systemFontOfSize:13];
    detTextLabel.textColor = cell.detailTextLabel.textColor;
    detTextLabel.backgroundColor = [UIColor clearColor];
    detTextLabel.tag = 3;
    detTextLabel.numberOfLines = 2;
    [cell.contentView addSubview:detTextLabel];
    cell.detailTextLabel.textColor = [UIColor clearColor];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.tag = 4;
    [cell.contentView addSubview:imageView];


    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (UITableViewCell *)cellWithTitle:(NSString*)title subtitle:(NSString*)subtitle time:(NSString*)time image:(NSString*)image
{
    UITableViewCell *cell = [self cellWithIdent:@"cell"];
    
    UILabel *timeLabel = (UILabel*)[cell viewWithTag:1];
    UILabel *textLabel = (UILabel*)[cell viewWithTag:2];
    UILabel *detTextLabel = (UILabel*)[cell viewWithTag:3];
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:4];
    
    // Update time label

    CGSize timeSize;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
        timeLabel.text = time;
        timeSize = [time sizeWithFont:timeLabel.font];
    } else {
        NSAttributedString *timeAttString = [YTHelper formatDateAttr:time size:12 color:[UIColor blueColor]];
        timeLabel.attributedText = timeAttString;
        timeSize = [timeAttString size];
    }
    CGFloat timeWidth = timeSize.width + 5;
    timeLabel.frame = CGRectMake(cell.bounds.size.width - timeWidth - 30, 5, timeWidth, timeSize.height);
    
    // Update title label
    
    CGFloat textFontSize = cell.textLabel.font.pointSize;
    textLabel.frame= CGRectMake(78, 2, cell.frame.size.width - timeWidth - 30 - 10 - 78, 21);
    textLabel.font = [UIFont boldSystemFontOfSize:textFontSize];
    textLabel.text = title;
    cell.textLabel.text = @" ";
    
    // Update subtitle label
    
    detTextLabel.frame= CGRectMake(78, 23, cell.frame.size.width - 30 -  78, 32);
    detTextLabel.text = [NSString stringWithFormat:@"%@\n ", subtitle];

    cell.detailTextLabel.text = @" ";
    
    imageView.frame = CGRectMake(5, (cell.frame.size.height - 18) / 2, 18, 18);
    if (image) {
        imageView.image = [YTHelper imageNamed:image];
        imageView.hidden = NO;
    } else {
        imageView.image = nil;
        imageView.hidden = YES;
    }
    
    [textLabel removeFromSuperview];
    [cell.contentView addSubview:textLabel];
    
    [timeLabel removeFromSuperview];
    [cell.contentView addSubview:timeLabel];
    
    [detTextLabel removeFromSuperview];
    [cell.contentView addSubview:detTextLabel];
    
    [imageView removeFromSuperview];
    [cell.contentView addSubview:imageView];
    
    for (UIView *view in cell.contentView.subviews) {
        view.alpha = 1;
    }
    
    return cell;
}

#pragma mark UIViewController methods

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

- (void)viewWillDisappear:(BOOL)animated
{
    [self deselectSelectedGab:animated];
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
    if ([YTModelHelper gabCountWithFilter:@""] >= 10) {
        return 0;
    }
    
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    NSInteger count = [delegate.randFriends count];
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
    
    if ([YTAppDelegate current].randFriends.count <= CONFIG_GHOST_FRIEND_COUNT) {
        return 0;
    }
    
    return 1;
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
    NSString *time = [YTHelper formatDate:[object valueForKey:@"last_date"]];
    NSString *image = read ? nil : @"newgab2";

    UITableViewCell *cell = [self cellWithTitle:title subtitle:subtitle time:time image:image];

    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];
    [avatarView setImageWithURL:[NSURL URLWithString:[object valueForKey:@"related_avatar"]] placeholderImage:[YTHelper imageNamed:@"avatar6"] options:SDWebImageRefreshCached];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUser:(NSDictionary*)user featured:(BOOL)featured
{
    NSString *title = user[@"name"];
    NSString *subtitle = NSLocalizedString(@"Tap me to start a new conversation", nil);
    NSString *time = featured ? NSLocalizedString(@"Featured", nil) : @"";
    NSString *image = featured ? @"star2" : nil;
    
    UITableViewCell *cell = [self cellWithTitle:title subtitle:subtitle time:time image:image];
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
    NSDictionary *friendData = [YTAppDelegate current].randFriends[row];
    NSDictionary *friend = [YTContactHelper findContactWithType:friendData[@"type"] value:friendData[@"value"]];
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
    NSString *subtitle = NSLocalizedString(@"Tap me to get more friends", nil);
    NSString *time = @"";
    NSString *image = nil;
    
    UITableViewCell *cell = [self cellWithTitle:title subtitle:subtitle time:time image:image];
    
    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];

    NSString *url = @"https://s3.amazonaws.com/backdoor_images/icon_114x114.png";
    [avatarView setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageRefreshCached];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForMoreAtRow:(NSInteger)row
{
    NSString *title = NSLocalizedString(@"Show More", nil);
    NSString *subtitle = NSLocalizedString(@"Show all of your Backdoor friends", nil);
    NSString *time = @"";
    NSString *image = nil;
    
    UITableViewCell *cell = [self cellWithTitle:title subtitle:subtitle time:time image:image];
    
    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];
    [avatarView setImage:[UIImage imageNamed:@"more2"]];
    
    return cell;
}

# pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];

    if (indexPath.section == SECTION_GABS) {
        NSManagedObject *object = [YTModelHelper gabForRow:indexPath.row  filter:self.searchBar.text];
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Thread Item"];
        self.selectedGabId = [object valueForKey:@"id"];
        [YTViewHelper showGabWithId:self.selectedGabId];
        return;
    }
    
    if (indexPath.section == SECTION_FRIENDS) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Friend Item"];
        NSDictionary *friendData = [YTAppDelegate current].randFriends[indexPath.row];
        NSDictionary *friend = [YTContactHelper findContactWithType:friendData[@"type"] value:friendData[@"value"]];
        [YTViewHelper showGabWithReceiver:friend];
        return;
    }
    
    if (indexPath.section == SECTION_MORE) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / More Item"];

        return;
    }
    
    if (indexPath.section == SECTION_SHARE) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Share Item"];
        [[YTSocialHelper sharedInstance] presentShareDialog];
        return;
    }
    
    if (indexPath.section == SECTION_FEATURED) {
        [[Mixpanel sharedInstance] track:@"Tapped Main View / Featured Users Item"];
        NSDictionary *user = [YTAppDelegate current].featuredUsers[indexPath.row];
        [YTViewHelper showGabWithReceiver:user];
        return;
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
    [self reloadData];
}
     
- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
