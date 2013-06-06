//
//  YTMainViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>

#import <UIImageView+WebCache.h>

#import "YTAppDelegate.h"
#import "YTMainViewController.h"
#import "YTHelper.h"
#import "YTContactHelper.h"
#import "YTModelHelper.h"
#import "YTApiHelper.h"
#import "YTViewHelper.h"
#import "YTConfig.h"

@implementation YTMainViewController

# pragma mark Custom methods

- (void)refreshWasRequested
{
    [YTApiHelper autoSync:NO];
}

- (void)composeButtonWasClicked
{
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
    
    UIImage *image = [UIImage imageNamed:@"newgab.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tag = 4;
    [cell.contentView addSubview:imageView];


    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings.png"] style:UIBarButtonItemStyleBordered target:[YTViewHelper class] action:@selector(showSettings)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeButtonWasClicked)];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Messages", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
    
    self.searchBar = [UISearchBar new];
    [self.searchBar sizeToFit];
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [UIImage imageNamed:@"navbar3.png"];
    self.tableView.tableHeaderView = self.searchBar;
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshWasRequested) forControlEvents:UIControlEventValueChanged];
    
   // self.title = NSLocalizedString(@"Backdoor", nil);
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navbartitle4.png"]];
    self.view.backgroundColor = [UIColor whiteColor];


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
    if (!self.searchBar.text || [self.searchBar.text isEqualToString:@""]) {
        return 3;
    } else {
        return 1;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    } else if (section == 1 && [self tableView:tableView  numberOfRowsInSection:1] > 0) {
        return NSLocalizedString(@"Featured users", nil);
    } else if (section == 2 && [self tableView:tableView  numberOfRowsInSection:2] > 0){
        return NSLocalizedString(@"Backdoor a friend", nil);
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [YTModelHelper gabCountWithFilter:self.searchBar.text];
    NSInteger ret = 0;
    
    if (section == 0) {
        ret = count;
    } else if (section == 1) {
        return [YTAppDelegate current].featuredUsers.count;
    } else if (section == 2) {
        ret = CONFIG_MAX_INDEX_OF_FB_FRIEND - count;
        ret = MAX(ret, CONFIG_MIN_INDEX_OF_FB_FRIEND);
        ret = MIN(ret, [[YTAppDelegate current].randFriends count]);
    }
    
    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [self tableView:tableView cellForGabAtRow:indexPath.row];
    } else if (indexPath.section == 1) {
        return [self tableView:tableView cellForUserAtRow:indexPath.row];
    } else if (indexPath.section == 2) {
        return [self tableView:tableView cellForFriendAtRow:indexPath.row];
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForGabAtRow:(NSInteger)row
{
    NSManagedObject *object = [YTModelHelper gabForRow:row  filter:self.searchBar.text];

    UITableViewCell *cell = [self cellWithIdent:@"cell"];
    
    UILabel *timeLabel = (UILabel*)[cell viewWithTag:1];
    UILabel *textLabel = (UILabel*)[cell viewWithTag:2];
    UILabel *detTextLabel = (UILabel*)[cell viewWithTag:3];
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:4];
    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];

    NSString *timeString = [YTHelper formatDate:[object valueForKey:@"last_date"]];
    CGSize timeSize;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
        timeLabel.text = timeString;
        timeSize = [timeString sizeWithFont:timeLabel.font];
    } else {
        NSAttributedString *timeAttString = [YTHelper formatDateAttr:timeString size:12 color:[UIColor blueColor]];
        timeLabel.attributedText = timeAttString;
        timeSize = [timeAttString size];
    }
    CGFloat timeWidth = timeSize.width + 5;
    timeLabel.frame = CGRectMake(cell.bounds.size.width - timeWidth - 30, 5, timeWidth, timeSize.height);

    BOOL read = [[object valueForKey:@"unread_count"] isEqualToNumber:@0];
    CGFloat textFontSize = cell.textLabel.font.pointSize;

    textLabel.frame= CGRectMake(78, 2, cell.frame.size.width - timeWidth - 30 - 10 - 78, 21);
    //textLabel.font = read ? [UIFont systemFontOfSize:textFontSize] : [UIFont boldSystemFontOfSize:textFontSize];
    textLabel.font = [UIFont boldSystemFontOfSize:textFontSize];
    textLabel.text = [YTModelHelper userNameForGab:object];
    cell.textLabel.text = @" "                                                                                          ;
    
    detTextLabel.frame= CGRectMake(78, 23, cell.frame.size.width - 30 -  78, 32);
    NSString* sum = [object valueForKey:@"content_summary"];
    detTextLabel.text = [NSString stringWithFormat:@"%@\n ", sum];

    cell.detailTextLabel.text = @" ";
    
    imageView.frame = CGRectMake(5, (cell.frame.size.height - imageView.frame.size.height) / 2, 15, 15);
    imageView.hidden = read;
    

    avatarView.frame = CGRectMake(26, 7, 45, 45);

    
    [textLabel removeFromSuperview];
    [cell addSubview:textLabel];
    
    [timeLabel removeFromSuperview];
    [cell addSubview:timeLabel];

    [detTextLabel removeFromSuperview];
    [cell addSubview:detTextLabel];
    
    [imageView removeFromSuperview];
    [cell addSubview:imageView];
    
    [avatarView removeFromSuperview];
    [cell addSubview:avatarView];
    
    [avatarView setImageWithURL:[NSURL URLWithString:[object valueForKey:@"related_avatar"]] placeholderImage:[UIImage imageNamed:@"avatar6.png"] options:SDWebImageRefreshCached];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUser:(NSDictionary*)user
{
    UITableViewCell *cell = [self cellWithIdent:@"cell_friend"];

    UIImageView *avatarView = (UIImageView*)[cell viewWithTag:5];
    avatarView.frame = CGRectMake(26, 6, 45, 45);
    
    UILabel *textLabel = (UILabel*)[cell viewWithTag:2];
    
    textLabel.frame= CGRectMake(78, 18, cell.frame.size.width - 93, 21);
    textLabel.font = [UIFont boldSystemFontOfSize:21];
    textLabel.text = user[@"name"];
    cell.textLabel.text = @" ";
    
    if ([user[@"type"] isEqualToString:@"facebook"]) {
        NSString *urls = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", user[@"value"]];
        [avatarView setImageWithURL:[NSURL URLWithString:urls] placeholderImage:[UIImage imageNamed:@"avatar6.png"] options:SDWebImageRefreshCached];
    } else if ([user[@"type"] isEqualToString:@"gpp"]) {
        NSString *urls = [NSString stringWithFormat:@"https://profiles.google.com/s2/photos/profile/%@?sz=50", user[@"value"]];
        [avatarView setImageWithURL:[NSURL URLWithString:urls] placeholderImage:[UIImage imageNamed:@"avatar6.png"] options:SDWebImageRefreshCached];
    } else {
        [avatarView setImage:nil];
    }
    
    
    [textLabel removeFromSuperview];
    [cell addSubview:textLabel];
    
    [avatarView removeFromSuperview];
    [cell addSubview:avatarView];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForFriendAtRow:(NSInteger)row
{
    NSDictionary *friendData = [YTAppDelegate current].randFriends[row];
    NSDictionary *friend = [YTContactHelper findContactWithType:friendData[@"type"] value:friendData[@"value"]];
    return [self tableView:tableView cellForUser:friend];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUserAtRow:(NSInteger)row
{
    NSDictionary *user = [YTAppDelegate current].featuredUsers[row];
    return [self tableView:tableView cellForUser:user];
}


# pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];

    if (indexPath.section == 0) {
        NSManagedObject *object = [YTModelHelper gabForRow:indexPath.row  filter:self.searchBar.text];
        self.selectedGabId = [object valueForKey:@"id"];
        [YTViewHelper showGabWithId:self.selectedGabId];
    } else if (indexPath.section == 1) {
        NSDictionary *user = [YTAppDelegate current].featuredUsers[indexPath.row];
        [YTViewHelper showGabWithReceiver:user];

    } else if (indexPath.section == 2) {
        NSDictionary *friendData = [YTAppDelegate current].randFriends[indexPath.row];
        NSDictionary *friend = [YTContactHelper findContactWithType:friendData[@"type"] value:friendData[@"value"]];
        [YTViewHelper showGabWithReceiver:friend];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
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
    if (indexPath.section == 0) {
        return 60;
    } else {
        return 58;
    }
}

#pragma mark UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self reloadData];
}
     
- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
