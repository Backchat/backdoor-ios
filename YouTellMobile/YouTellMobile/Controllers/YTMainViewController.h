//
//  YTMainViewController.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YTViewController.h"

@interface YTMainViewController : UITableViewController  <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

/*
@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
*/

@property (strong, nonatomic) UISearchBar *searchBar;

@property (strong, nonatomic) NSNumber *selectedGabId;
@property (assign, nonatomic) BOOL showMoreItem;
@property (assign, nonatomic) BOOL showShareItem;

- (void)refreshWasRequested;
- (void)composeButtonWasClicked;
- (void)reloadData;

@end
