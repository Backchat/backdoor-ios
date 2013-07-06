//
//  YTContactWidget.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTContactWidget.h"
#import "YTContactHelper.h"

#import "YTContactsViewController.h"
#import "YTSocialHelper.h"
#import "YTGPPHelper.h"
#import "YTHelper.h"

#define HEIGHT 30.0f
#define PADDING 12.0f

 
@implementation YTContactWidget

- (id)initWithFrame:(CGRect)frame tableView:(UITableView*)tableView
{
    self = [super initWithFrame:frame];
    if (!self) {
        return self;
    }
    
    self.backgroundColor = [UIColor whiteColor];
    
    self.textField = [[UITextField alloc] init];
    self.label = [[UILabel alloc] init];
    
    self.label.text = NSLocalizedString(@"To:", nil);
    self.label.font = [UIFont systemFontOfSize:15];
    self.label.textColor = [UIColor grayColor];
    [self.label sizeToFit];
    
    CGFloat frameX = frame.origin.x + PADDING;
    CGFloat frameY = frame.origin.y + (frame.size.height - self.label.frame.size.height) / 2;
    self.label.frame = CGRectMake(frameX, frameY, self.label.frame.size.width, self.label.frame.size.height);
    
    CGFloat receiverFieldX = frame.origin.x + self.label.frame.origin.x + self.label.frame.size.width + 5;
    CGFloat receiverFieldY = frame.origin.y + (frame.size.height - HEIGHT) / 2;
    CGFloat receiverFieldW = frame.size.width - self.label.frame.size.width - 5 - (2 * PADDING);
    CGFloat receiverFieldH = HEIGHT;
    
    self.textField.frame = CGRectMake(receiverFieldX, receiverFieldY, receiverFieldW, receiverFieldH);
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.textField.text = @"";
    self.textField.delegate = self;
    self.textField.clearButtonMode = UITextFieldViewModeNever;
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    self.addButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    CGRect buttonFrame = self.addButton.frame;
    buttonFrame.origin.y = self.frame.origin.y + (self.frame.size.height - buttonFrame.size.height) / 2;
    buttonFrame.origin.x = self.textField.frame.origin.x + self.textField.frame.size.width - buttonFrame.size.width - 5;
    self.addButton.frame = buttonFrame;
    [self.addButton addTarget:self action:@selector(addButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
    
   
    self.tableView = tableView;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = YES;
    self.selectedContact = nil;
    
    [self updateButtons];
    
    [self addSubview:self.label];
    [self addSubview:self.textField];
    [self addSubview:self.addButton];
    
    return self;
}

- (void)textDidChange:(NSString*)text
{
    if(self.allContacts.count != 0)
        self.tableView.hidden = [text isEqualToString:@""];

    self.selectedContact = nil;
    self.contacts = [[YTContactHelper sharedInstance] findContactsWithString:text grouped:NO];
    [self.tableView reloadData];
    [self updateButtons];

    [self.delegate changedSelectedContact:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *text = [self.textField.text stringByReplacingCharactersInRange:range withString:string];

    [self textDidChange:text];
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self textDidChange:@""];
    return YES;
}

- (void)setHidden:(BOOL)hidden
{
    self.allContacts = [[YTContactHelper sharedInstance] findContactsWithString:@"" grouped:NO];

    if(hidden)
        self.tableView.hidden = YES;
    else {
        if(self.allContacts.count == 0)
            self.tableView.hidden = NO;
        else
            self.tableView.hidden = YES;
    }
    
    [super setHidden:hidden];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.contacts = [[YTContactHelper sharedInstance] findContactsWithString:textField.text grouped:NO];
    self.textField.textColor = [UIColor blackColor];
    [self.tableView reloadData];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(self.allContacts.count != 0)
        self.tableView.hidden = YES;
    self.contacts = nil;
    self.textField.textColor = self.selectedContact ? [UIColor blackColor] : [UIColor redColor];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSArray *contacts = (tableView == self.tableView) ? self.contacts : self.allContacts;
    NSInteger socialSection = ([[YTSocialHelper sharedInstance] isGPP]) ? 1 : 0;
    return contacts ? [contacts count] + socialSection : socialSection;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *contacts = (tableView == self.tableView) ? self.contacts : self.allContacts;
    
    if (section == contacts.count && [[YTSocialHelper sharedInstance] isGPP]) {
        return nil;
    } else {
        return contacts[section][0];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *contacts = (tableView == self.tableView) ? self.contacts : self.allContacts;

    if (section == contacts.count && [[YTSocialHelper sharedInstance] isGPP]) {
        return 1;
    } else {
        return [contacts[section][1] count];
    }
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *result = [NSMutableArray new];
    NSArray *contacts = (tableView == self.tableView) ? self.contacts : self.allContacts;
    for (NSArray *section in contacts) {
        [result addObject:section[0]];
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *contacts = (tableView == self.tableView) ? self.contacts : self.allContacts;

    UITableViewCell *cell;
    
    if (indexPath.section == contacts.count && [[YTSocialHelper sharedInstance] isGPP]) {
        cell = [self cellWithTable:tableView ident:@"cell_social"];

    } else {
        NSDictionary *record = contacts[indexPath.section][1][indexPath.row][0];

        cell = [self cellWithTable:tableView ident:@"cell"];
        cell.textLabel.text = record[@"name"];
    }
    
/*
    if ([record[@"type"] isEqualToString:@"facebook"]) {
        cell.detailTextLabel.text = record[@"title"];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@", record[@"title"], record[@"value"]];
    }
*/
    return cell;
}

- (UITableViewCell *)cellWithTable:(UITableView*)table ident:(NSString*)ident
{
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:ident];
    
    if (cell) {
        return cell;
    }
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if ([ident isEqualToString:@"cell_social"]) {
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[YTHelper imageNamed:@"gpp_tableitem2"]];
        
        UILabel *label = [UILabel new];
        
        label.textColor = [UIColor whiteColor];
        label.text = NSLocalizedString(@"Want friends on Backdoor?\nNo worries, Share on Google+", nil);
        label.numberOfLines = 2;
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.frame = CGRectMake(0, 0, 320, 44);
        label.backgroundColor = [UIColor clearColor];
        
        [cell addSubview:imageView];
        [cell addSubview:label];
        
    }
    
    return cell;
}

- (void)selectContact:(NSDictionary *)contact
{
    self.selectedContact = contact;
    self.textField.text = contact[@"name"];

    self.textField.textColor = [UIColor blackColor];
    
    [self updateButtons];
    [self.delegate changedSelectedContact:contact];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *contacts = (tableView == self.tableView) ? self.contacts : self.allContacts;
    
    if (tableView != self.tableView) {
        [self.delegate hideContactViewController];
    }
    
    if (indexPath.section == contacts.count && [[YTSocialHelper sharedInstance] isGPP]) {
        [[YTGPPHelper sharedInstance] presentShareDialog];
    } else {
        NSDictionary *record = contacts[indexPath.section][1][indexPath.row][0];
        [self selectContact:record];
        [self.textField resignFirstResponder];
    }

}

- (void)updateButtons
{
    self.addButton.hidden = !!self.selectedContact;
    self.textField.clearButtonMode = self.selectedContact ? UITextFieldViewModeAlways : UITextFieldViewModeNever;
}

- (void)addButtonWasPressed:(id)sender
{
    [self.textField resignFirstResponder];
    self.contactsView = [YTContactsViewController new];
    self.contactsView.tableView.dataSource = self;
    self.contactsView.tableView.delegate = self;
    self.contactsView.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contactsView.tableView reloadData];
    
    self.contactsView.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleDone target:self.delegate action:@selector(hideContactViewController)];
    [self.delegate showContactViewController:self.contactsView];

}



@end

