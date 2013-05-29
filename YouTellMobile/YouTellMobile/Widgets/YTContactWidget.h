//
//  YTContactWidget.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YTContactsViewController.h"

@protocol YTContactWidgetDelegate;

@interface YTContactWidget : UIView <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) UITextField *textField;
@property (strong, nonatomic) UIButton *addButton;
@property (strong, nonatomic) UILabel *label;
@property (weak, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSArray *contacts;
@property (strong, nonatomic) NSArray *allContacts;
@property (strong, nonatomic) NSDictionary *selectedContact;
@property (weak, nonatomic) id<YTContactWidgetDelegate> delegate;

- (id)initWithFrame:(CGRect)frame tableView:(UITableView*)tableView;
- (void)selectContact:(NSDictionary *)contact;

@property (strong, nonatomic) YTContactsViewController *contactsView;


@end



@protocol YTContactWidgetDelegate <NSObject>

- (void)changedSelectedContact:(NSDictionary*)contact;
- (void)showContactViewController:(YTContactsViewController*)contactViewController;
- (void)hideContactViewController;


@end
