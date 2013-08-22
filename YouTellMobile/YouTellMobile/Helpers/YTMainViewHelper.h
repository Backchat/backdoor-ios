//
//  YTMainViewHelper.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTViewHelper.h"
#import "YTGab.h"

@interface YTMainViewHelper : YTViewHelper

+ (YTMainViewHelper*)sharedInstance;
- (UITableViewCell *)cellWithTableView:(UITableView*)tableView;
- (UITableViewCell *)cellWithTableView:(UITableView*)tableView title:(NSString*)title subtitle:(NSString*)subtitle time:(NSString*)time
image:(NSString*)image avatar:(NSString*)avatar placeHolderImage:(UIImage*)placeHolderImage backgroundColor:(UIColor*)backgroundColor;
- (void)addCellSubViewsToView:(UIView*)view;
- (void)setCellValuesInView:(UIView*)view title:(NSString*)title subtitle:(NSString*)subtitle time:(NSString*)time
                      image:(NSString*)image avatar:(NSString*)avatar placeHolderImage:(UIImage*)placeHolderImage;

- (UITableViewCell*) cellWithGab:(YTGab*)gab andTableView:(UITableView*)tableView;
@end
