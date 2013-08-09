//
//  YTInviteContactViewController.h
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTContact.h"
#import <AddressBookUI/ABPeoplePickerNavigationController.h>

@interface YTInviteContactViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UITableView *contactsTable;
@property (strong, nonatomic) YTContact* contact;
@end
