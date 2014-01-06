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
@property (retain, nonatomic) NSMutableDictionary* alphaByIndex;
@property (retain, nonatomic) NSMutableArray* selectedContactIDs;
@property (assign, nonatomic) bool allSelected;
@property (retain, nonatomic) UIImageView* miniBar;
@property (retain, nonatomic) UILabel* statusLabel;

- (YTContact*) contactAtIndexPath:(NSIndexPath*)indexPath;
- (void)buildIndexedList;
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
    self.tableView.sectionHeaderHeight = 25;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    /* we use contacts for now, and don't try to filter out the people we know.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendsUpdated:)
                                                 name:YTFriendNotification object:nil];*/
    
    
    // Do any additional setup after loading the view.
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered
                                                                                          target:self
                                                                                          action:@selector(cancelButtonWasClicked)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(nextButton)];

    UIImage* image = [YTHelper imageNamed:@"navbar-greyed"];
    [self.navigationItem.rightBarButtonItem setBackgroundImage:image
                                                      forState:UIControlStateDisabled
                                                    barMetrics:UIBarMetricsDefault];
        
    self.tableView.tableHeaderView = nil;
    self.searchBar.frame = CGRectMake(0,0,self.view.frame.size.width, self.searchBar.frame.size.height);
    
    self.miniBar = [[UIImageView alloc]initWithFrame:CGRectMake(0, self.searchBar.frame.size.height,
                                                                self.view.frame.size.width, 0)];
    self.miniBar.image = [YTHelper imageNamed:@"minibar"];
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,5,self.view.frame.size.width, 20)];
    self.statusLabel.font = [UIFont systemFontOfSize:18];
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.backgroundColor = [UIColor clearColor];
    self.miniBar.clipsToBounds = YES;

    [self.view addSubview:self.miniBar];
    [self.view addSubview:self.searchBar];

    [self.miniBar addSubview:self.statusLabel];
    
    [self updateStatusBar:NO];
}

- (void)nextButton
{
    /* everyone now has a phone number always since we use contacts.
     YTInviteContactViewController* view = [YTInviteContactViewController new];
     view.contact = [self.filteredContacts contactAtIndex:indexPath.row];
     [self.navigationController pushViewController:view animated:YES];*/
     
    YTInviteContactComposeViewController* compose = [YTInviteContactComposeViewController new];
    NSMutableArray* contacts = [[NSMutableArray alloc] initWithCapacity:self.selectedContactIDs.count];
    for(int i=0;i<self.contacts.count;i++) {
        YTContact* c = [self.contacts contactAtIndex:i];
        if([self.selectedContactIDs indexOfObject:c.socialID] != NSNotFound) {
            [contacts addObject:c];
        }
    }
    
    compose.contacts = contacts;
    [self.navigationController pushViewController:compose animated:YES];

}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(!self.isSearching) {
        if(section == 0)
            return nil;
        else {
            if([[self.alphaByIndex objectForKey:[NSNumber numberWithInt:section-1]] count] > 0)
                return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section-1];
            else
                return nil;
        }
    }
    else
        return nil;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if(self.isSearching)
        return nil;
    else {
        NSMutableArray* ar = [[NSMutableArray alloc] initWithArray:[[UILocalizedIndexedCollation currentCollation]  sectionIndexTitles]];
        [ar insertObject:@"" atIndex:0];
        return ar;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    int realSec = index;
    if(!self.isSearching) {
        if(index == 0)
            return 0;
        else
            realSec = realSec - 1;
    }
    
    return [[UILocalizedIndexedCollation currentCollation]  sectionForSectionIndexTitleAtIndex:realSec];
}

- (void)buildIndexedList
{    
    self.alphaByIndex = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* tmp = [[NSMutableDictionary alloc] init];
    
    for(int i=0;i<self.filteredContacts.count;i++) {
        YTContact* contact = [self.filteredContacts contactAtIndex:i];
        int sect = [[UILocalizedIndexedCollation currentCollation]
                    sectionForObject:contact collationStringSelector:@selector(first_name)];
        NSMutableArray* ar = [tmp objectForKey:[NSNumber numberWithInt:sect]];
        if(!ar) {
            ar = [[NSMutableArray alloc] init];
            [tmp setObject:ar forKey:[NSNumber numberWithInt:sect]];
        }
        
        [ar addObject:contact];
    }
    
    for(id key in tmp) {
        NSMutableArray* val = tmp[key];
        NSArray* real = [[UILocalizedIndexedCollation currentCollation] sortedArrayFromArray:val collationStringSelector:@selector(first_name)];
        [self.alphaByIndex setObject:real forKey:key];
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.selectedContactIDs = [[NSMutableArray alloc] init];
    self.contacts = nil;
    self.allSelected = false;
    self.tableView.hidden = YES;
    [self updateStatusBar:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [YTAddressBookHelper fetchContacts:^(YTContacts *c) {
        self.contacts = c;
        self.filteredContacts = [[YTContacts alloc] initWithContacts:self.contacts withFilter:self.searchBar.text];
        [self buildIndexedList];
        [self selectAll:YES updateCells:NO animated:NO];
        self.tableView.hidden = NO;
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

- (bool)isSearching
{
    return self.searchBar.text.length > 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(!self.alphaByIndex)
        return 0;
    else {
        int showInvite = self.isSearching ? 0 : 1 ;
        return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count] + showInvite;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int realSec = section;
    if(!self.isSearching) {
        if(section == 0)
            return 1;
        else
            realSec = realSec - 1;
    }
    
    return [[self.alphaByIndex objectForKey:[NSNumber numberWithInt:section-1]] count];
}

- (void)selectAll:(bool)state updateCells:(bool)updateCells animated:(BOOL)animated
{
    if(state) {
        self.selectedContactIDs = [[NSMutableArray alloc] initWithCapacity:self.contacts.count];
        for(int i=0;i<self.contacts.count;i++) {
            [self.selectedContactIDs addObject:[self.contacts contactAtIndex:i].socialID];
        }
    }
    else {
        self.selectedContactIDs = [[NSMutableArray alloc] init];
    }
    
    if(updateCells) {
        for(UITableViewCell* cell in self.tableView.visibleCells) {
            [self updateCellInPlace:cell selected:state];
        }
    }
    
    [self updateStatusBar:animated];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = @"";
    NSString *subtitle = @"";
    NSString *time = @"";
    NSString* avatarUrl = nil;
    UIImage* placeHolder =nil;
    NSString* checkImage = nil;
    UITableViewCellAccessoryType type;
    
    if(indexPath.section == 0 && !self.isSearching) {
        avatarUrl = @"invite_gab_cell_icon";

        if(self.allSelected) {
            title = NSLocalizedString(@"Unselect All", nil);
            subtitle = NSLocalizedString(@"Tap me to unselect all your contacts", nil);
        }
        else {
            title = NSLocalizedString(@"Select All", nil);
            subtitle = NSLocalizedString(@"Tap me to select all your contacts", nil);
        }
    }
    else {
        YTContact* c = [self contactAtIndexPath:indexPath];
        
        title = c.name;
        subtitle = c.phone_number; //NSLocalizedString(@"Send text to invite", nil);
        time = c.localizedType;
        placeHolder = [YTHelper imageNamed:@"avatar6"];
        avatarUrl = c.avatarUrl;
        
        if([self.selectedContactIDs indexOfObject:c.socialID] != NSNotFound) {
            checkImage = @"selected-invite-circle";
        }
        else {
            checkImage = @"unselected-invite-circle";
        }
        
        type = UITableViewCellAccessoryNone;
    }
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time
                                                                           image:checkImage
                                                                          avatar:avatarUrl
                                                                placeHolderImage:placeHolder
                                                                 backgroundColor:[UIColor whiteColor]];
    
    //[UIColor colorWithRed:234.0/255.0 green:242.0/255.0 blue:246.0/255.0 alpha:1.0]];

    cell.accessoryType = type;
    
    return cell;
}


- (YTContact*) contactAtIndexPath:(NSIndexPath*)indexPath
{
    NSArray* sect = [self.alphaByIndex objectForKey:[NSNumber numberWithInt:indexPath.section-1]];
    return [sect objectAtIndex:indexPath.row];    
}

- (void) updateStatusBar:(BOOL)animated
{
    bool selectedOne = self.selectedContactIDs && self.selectedContactIDs.count >= 1;
    if(selectedOne) {
        self.statusLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d People Selected", nil), self.selectedContactIDs.count];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    //TODO DRY
    
    if(!animated) {
        if(selectedOne) {
            self.miniBar.frame = CGRectMake(0,self.searchBar.frame.size.height,self.view.frame.size.width, 30);
            
        }
        else {
            self.miniBar.frame = CGRectMake(0,self.searchBar.frame.size.height,self.view.frame.size.width, 0);
        }

        int offHeight = self.searchBar.frame.size.height + self.miniBar.frame.size.height;
        self.tableView.frame = CGRectMake(0, offHeight, self.view.frame.size.width, self.view.frame.size.height - offHeight);
    }
    else {
        CGFloat duration = 0.3;

        [UIView animateWithDuration:duration animations:^{
            if(selectedOne) {
                self.miniBar.frame = CGRectMake(0,self.searchBar.frame.size.height,self.view.frame.size.width, 30);
            }
            else {
                self.miniBar.frame = CGRectMake(0,self.searchBar.frame.size.height,self.view.frame.size.width, 0);
            }
            
            
            int offHeight = self.searchBar.frame.size.height + self.miniBar.frame.size.height;
            self.tableView.frame = CGRectMake(0, offHeight, self.view.frame.size.width, self.view.frame.size.height - offHeight);

        }];
    }
    
    //check all state
    bool newState;
    if(self.selectedContactIDs && self.selectedContactIDs.count == self.contacts.count) {
        newState = YES;
    }
    else {
        newState = NO;
    }
    
    if(newState != self.allSelected) {
        self.allSelected = newState;
        if(!self.isSearching) {
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            
            UILabel* subtitle = (UILabel*)[cell viewWithTag:3];
            UILabel* title = (UILabel*)[cell viewWithTag:2];
            
            if(self.allSelected) {
                [title setText:NSLocalizedString(@"Unselect All", nil)];
                [subtitle setText:[NSString stringWithFormat:@"%@\n ", NSLocalizedString(@"Tap me to unselect all your contacts", nil)]];
            }
            else {
                [title setText:NSLocalizedString(@"Select All", nil)];
                [subtitle setText:[NSString stringWithFormat:@"%@\n ", NSLocalizedString(@"Tap me to select all your contacts", nil)]];
            }
        }        
    }
}

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
        return nil;
    }
    else {
        if(!self.isSearching) {
            if(indexPath.section == 0) {
                [self selectAll:!self.allSelected updateCells:YES animated:YES];
                
                return nil;
            }
        }
        
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        YTContact* c = [self contactAtIndexPath:indexPath];
        bool selected = [self.selectedContactIDs indexOfObject:c.socialID] != NSNotFound;
        if(selected) {
            [self.selectedContactIDs removeObject:c.socialID];
        }
        else {
            [self.selectedContactIDs addObject:c.socialID];
        }
        [self updateCellInPlace:cell selected:!selected];
        
        [self updateStatusBar:YES];
        
        return nil;
    }
}

- (void)updateCellInPlace:(UITableViewCell*) cell selected:(bool)selected
{
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:4];

    if(selected) {
        [imageView setImage:[YTHelper imageNamed:@"selected-invite-circle"]];
    }
    else {
        [imageView setImage:[YTHelper imageNamed:@"unselected-invite-circle"]];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.filteredContacts = [[YTContacts alloc] initWithContacts:self.contacts withFilter:searchText];
    [self buildIndexedList];
    [self.tableView reloadData];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    [self.tableView reloadSectionIndexTitles];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    [self.tableView reloadSectionIndexTitles];
}

@end
