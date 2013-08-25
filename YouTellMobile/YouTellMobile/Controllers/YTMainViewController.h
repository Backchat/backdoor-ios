//
//  YTMainViewController.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YTViewController.h"

@interface YTMainViewController : UITableViewController  <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
- (void)setupNavBar;
@end
