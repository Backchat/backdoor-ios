//
//  YTBaseSettingsViewController.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTViewController.h"

@interface YTBaseSettingsViewController : YTViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *tableData;

- (void)openURL:(NSString*)url title:(NSString*)title;

@end
