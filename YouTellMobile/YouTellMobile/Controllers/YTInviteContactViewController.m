//
//  YTInviteContactViewController.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Mixpanel.h>

#import "YTInviteContactViewController.h"
#import "YTContacts.h"
#import <AddressBook/AddressBook.h>
#import "YTAddressBookHelper.h"
#import "YTAppDelegate.h"
#import "YTHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "YTInviteContactComposeViewController.h"
#import "YTMainViewHelper.h"

@interface YTInviteContactViewController ()
@property (nonatomic, retain) YTContacts* possibleContacts;
@property (nonatomic, retain) YTInviteContactComposeViewController* compose;
@end


@implementation YTInviteContactViewController

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
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];

    self.headerLabel.text = [NSString stringWithFormat:NSLocalizedString(@"What's %@'s number?", nil),
                        self.contact.name];
    
    self.title = NSLocalizedString(@"New Invite", nil);
    //cancel please
    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonWasClicked)];

    self.contactsTable.frame = CGRectMake(self.contactsTable.frame.origin.x,
                                          self.contactsTable.frame.origin.y,
                                          self.view.frame.size.width,
                                          self.view.frame.size.height - self.contactsTable.frame.origin.y);
    self.contactsTable.tableFooterView = [UIView new];
    self.contactsTable.backgroundColor = [UIColor clearColor];
    
    [YTAddressBookHelper fetchContactsFromAddressBookByContact:self.contact
                                                       success:^(YTContacts *c) {
                                                           self.possibleContacts = c;
                                                           [self.contactsTable reloadData];
                                                       }];
    
    self.compose = [[YTInviteContactComposeViewController alloc] init];    
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case 0:
            return MIN(self.possibleContacts.count, 3);
        case 1:
            return 1;
        default:
            return 0;
    }
    
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    NSString* title = @"";
    NSString* subtitle = @"";
    NSString* time = @"";
    UIImage* image = nil;

    if(indexPath.section == 0) {
        YTContact* c = [self.possibleContacts contactAtIndex:indexPath.row];
        title = c.name;
        subtitle = c.phone_number;
        image = c.image;
    }
    else {
        image = [YTHelper imageNamed:@"choose_address_book"];
    }
    cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time
                                                          image:nil
                                                         avatar:nil
                                               placeHolderImage:image
                                                backgroundColor:[UIColor whiteColor]];

    if(indexPath.section == 1) {
        //for some reason, iOS is not letting us have two cell types in the same UITableView, though that
        //should be just fine. urgh.
        UILabel *textLabel = (UILabel*)[cell viewWithTag:3];
        textLabel.text = @"Choose from my address book";
        CGFloat fontsize = 15;
        textLabel.frame = CGRectMake(textLabel.frame.origin.x,
                                     (60-fontsize)/2,
                                     self.view.frame.size.width  - textLabel.frame.origin.x,
                                     fontsize);
        textLabel.font = [UIFont systemFontOfSize:fontsize];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:NO];
    
    switch(indexPath.section) {
        case 0:
        {
            [[Mixpanel sharedInstance] track:@"Tapped Invite Contact View / Contact Item"];

            YTContact* c = [self.possibleContacts contactAtIndex:indexPath.row];
            [self showInviteViewForContact:c];
            return;
        }
        case 1:
        {
            [[Mixpanel sharedInstance] track:@"Tapped Invite Contact View / Address Book Item"];

            ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
            picker.displayedProperties = @[[NSNumber numberWithInt:kABPersonPhoneProperty]];
            picker.peoplePickerDelegate = self;
            [picker.navigationBar setBackgroundImage:[YTHelper imageNamed:@"navbar3"] forBarMetrics:UIBarMetricsDefault];
            [self presentModalViewController:picker animated:YES];

            return;
        }
    }
    
}
- (void) cancelButtonWasClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setHeaderLabel:nil];
    [self setContactsTable:nil];
    [super viewDidUnload];
}

- (void)showInviteViewForContact:(YTContact*)c
{
    NSLog(@"%@ - %@", c.name, c.phone_number);
    self.compose.contact = c;
    [[YTAppDelegate current].navController pushViewController:self.compose animated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [peoplePicker dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    [peoplePicker dismissModalViewControllerAnimated:YES];
    YTContact* c = [self.contact copy];
    c.first_name = (__bridge_transfer NSString*) ABRecordCopyValue(person, kABPersonFirstNameProperty);
    c.last_name = (__bridge_transfer NSString*) ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    ABMutableMultiValueRef multi = ABRecordCopyValue(person, property);
    c.phone_number = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(multi,
                                                                                ABMultiValueGetIndexForIdentifier(multi, identifier));

    [self showInviteViewForContact:c];

    return NO;
}
@end
