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
@property (nonatomic, retain) UITextField* phoneField;
@property (nonatomic, retain) UIButton* phoneGo;
@property (nonatomic, retain) UITableViewCell* phoneCell;
@property (nonatomic, retain) NSString* enterLiteral;
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
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonWasClicked)];

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
    
    self.phoneField = nil;
    self.phoneGo = nil;
    
    self.phoneCell = [[UITableViewCell alloc] init];
    
    [[YTMainViewHelper sharedInstance] addCellSubViewsToView:self.phoneCell.contentView];
    [[YTMainViewHelper sharedInstance] setCellValuesInView:self.phoneCell
                                                     title:nil
                                                  subtitle:nil
                                                      time:nil
                                                     image:nil
                                                    avatar:nil
                                          placeHolderImage:[YTHelper imageNamed:@"enter_phone_number"]];
    UILabel *textLabel = (UILabel*)[self.phoneCell viewWithTag:3];
    CGRect frame = CGRectMake(textLabel.frame.origin.x, 20,
                              self.view.frame.size.width - textLabel.frame.origin.x,
                              20);
    self.phoneField = [[UITextField alloc] initWithFrame:frame];
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;
    self.phoneField.font = [UIFont systemFontOfSize:15];
    [self.phoneCell.contentView addSubview:self.phoneField];
    self.enterLiteral = NSLocalizedString(@"Enter a phone number", nil);
    self.phoneField.text = self.enterLiteral;
    
    self.phoneCell.backgroundView = [UIView new];
    self.phoneCell.backgroundView.backgroundColor = [UIColor whiteColor];
    [self.phoneField addTarget:self action:@selector(phoneFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    self.phoneGo = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    NSString* title = @"Invite";
    self.phoneGo.frame = CGRectMake(250, 17,
                                    50, 25);
    self.phoneGo.alpha = 0.0;
    [self.phoneGo setTitle:title forState:UIControlStateNormal];
    [self.phoneGo setTitle:title forState:UIControlStateHighlighted];
    [self.phoneGo setTitle:title forState:UIControlStateDisabled];
    [self.phoneGo setBackgroundImage:[YTHelper imageNamed:@"clue_button_inactive"] forState:UIControlStateNormal];
    [self.phoneGo setBackgroundImage:[YTHelper imageNamed:@"clue_button_active"] forState:UIControlStateHighlighted];
    [self.phoneGo setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.phoneGo setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

    [self.phoneCell.contentView addSubview:self.phoneGo];
    [self.phoneGo addTarget:self action:@selector(phoneGo:) forControlEvents:UIControlEventTouchUpInside];

    textLabel.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.phoneField resignFirstResponder];
    self.phoneField.text = self.enterLiteral;
    self.phoneGo.alpha = 0.0;
    [self.contactsTable setContentOffset:CGPointMake(0, 0) animated:NO];
}

- (void)keyboardWillShow:(NSNotification*)note
{
    UIView* cell = self.phoneCell;
    CGPoint origin = cell.frame.origin;
    CGPoint o = CGPointMake(0, origin.y);
    self.phoneField.text = @"";
    [UIView animateWithDuration:[YTHelper keyboardAnimationDurationForNotification:note]
                     animations:^{
                         [self.contactsTable setContentOffset:o animated:NO];
                     } completion:^(BOOL finished) {
                     }];
}

- (void)keyboardWillHide:(NSNotification*)note
{
    self.phoneField.text = self.enterLiteral;
    self.phoneGo.alpha = 0.0;
    
    [UIView animateWithDuration:[YTHelper keyboardAnimationDurationForNotification:note]
                     animations:^{
                         [self.contactsTable setContentOffset:CGPointMake(0, 0) animated:NO];
                     } completion:^(BOOL finished) {
                     }];

}

- (void)phoneButtonToggle:(BOOL)state
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.phoneGo.alpha = state ? 1.0 : 0.0;
                     }
                     completion:^(BOOL finished){
                     }];
}

- (void)phoneFieldDidChange:(NSNotification*)note
{
    if(![self.phoneField.text isEqualToString:@"Enter a phone number"] &&
       self.phoneField.text.length > 0) {
        [self phoneButtonToggle:TRUE];
    }
    else {
        [self phoneButtonToggle:FALSE];
    }
}

- (void)phoneGo:(NSNotification*)note
{
    NSString* phone = self.phoneField.text;
    YTContact* c = [self.contact copy];
    c.phone_number = phone;
    [self showInviteViewForContact:c];
}


- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case 0:
            return MIN(self.possibleContacts.count, 3);
        case 1:
            return 2;
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
        if(indexPath.row == 0) {
            //choose address book
            image = [YTHelper imageNamed:@"choose_address_book"];
        }
        else {
            return self.phoneCell;
        }
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
        CGFloat fontsize = 15;
        textLabel.frame = CGRectMake(textLabel.frame.origin.x,
                                     20,
                                     self.view.frame.size.width  - textLabel.frame.origin.x,
                                     fontsize);
        textLabel.text = NSLocalizedString(@"Choose from my address book", nil);
        textLabel.numberOfLines = 1;
        textLabel.font = [UIFont systemFontOfSize:fontsize];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSIndexPath*)tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 1 && indexPath.row == 1)
    {
        [[Mixpanel sharedInstance] track:@"Tapped Invite Contact View / Phone Number entry"];
        [self.phoneField becomeFirstResponder];
        return nil;
    }
    else
        return indexPath;
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
            if(indexPath.row == 0) {
                [[Mixpanel sharedInstance] track:@"Tapped Invite Contact View / Address Book Item"];
                
                ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
                picker.displayedProperties = @[[NSNumber numberWithInt:kABPersonPhoneProperty]];
                picker.peoplePickerDelegate = self;
                [picker.navigationBar setBackgroundImage:[YTHelper imageNamed:@"navbar3"] forBarMetrics:UIBarMetricsDefault];
                [self presentModalViewController:picker animated:YES];
            }

            return;
        }
    }
    
}

- (void) cancelButtonWasClicked
{
    if([self.phoneField isFirstResponder])
        [self.phoneField resignFirstResponder];
    else
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
    self.compose.contacts = @[c];
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
