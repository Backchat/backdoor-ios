//
//  YTMainViewHelper.h
//  Backdoor
//
//  Created by Łukasz S on 7/6/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTViewHelper.h"

@interface YTMainViewHelper : YTViewHelper

+ (YTMainViewHelper*)sharedInstance;
- (UITableViewCell *)cellWithTableView:(UITableView*)tableView;
- (UITableViewCell *)cellWithTableView:(UITableView*)tableView title:(NSString*)title subtitle:(NSString*)subtitle time:(NSString*)time image:(NSString*)image;

@end
