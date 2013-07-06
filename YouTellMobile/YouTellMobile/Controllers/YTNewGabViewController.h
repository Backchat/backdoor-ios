//
//  YTNewGabViewController.h
//  Backdoor
//
//  Created by Łukasz S on 7/6/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTViewController.h"

@interface YTNewGabViewController : YTViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *contacts;

@end
