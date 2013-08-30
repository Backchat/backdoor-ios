//
//  YTTableViewController.h
//  Backdoor
//
//  Created by Lin Xu on 8/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YTTableViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIActivityIndicatorView* spinner;

- (void) showSpinner;
- (void) hideSpinner;

- (void) setupNavBar;
- (void) cancelButtonWasClicked;
@end
