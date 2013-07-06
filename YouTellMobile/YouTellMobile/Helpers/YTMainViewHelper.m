//
//  YTMainViewHelper.m
//  Backdoor
//
//  Created by Łukasz S on 7/6/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTMainViewHelper.h"
#import "YTHelper.h"

#import <QuartzCore/QuartzCore.h>

@implementation YTMainViewHelper

+ (YTMainViewHelper*)sharedInstance
{
    static YTMainViewHelper *instance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        instance = [YTMainViewHelper new];
    });
    return instance;
}

- (UITableViewCell *)cellWithTableView:(UITableView*)tableView
{
    NSString *ident = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    
    if (cell) {
        return cell;
    }
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident];

    
    UIImageView *avatarView = [[UIImageView alloc] init];
    avatarView.tag = 5;
    avatarView.layer.cornerRadius = 5;
    avatarView.layer.masksToBounds = YES;
    avatarView.frame = CGRectMake(26, 7, 45, 45);
    [cell.contentView addSubview:avatarView];
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textLabel.font = [UIFont systemFontOfSize:12];
    textLabel.textColor = cell.textLabel.textColor;
    textLabel.tag = 2;
    textLabel.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:textLabel];
    cell.textLabel.textColor = [UIColor clearColor];
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.font = [UIFont systemFontOfSize:12];
    timeLabel.textColor = [UIColor blueColor];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.tag = 1;
    
    [cell.contentView addSubview:timeLabel];
    
    UILabel *detTextLabel = [[UILabel alloc] init];
    detTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    detTextLabel.font = [UIFont systemFontOfSize:13];
    detTextLabel.textColor = cell.detailTextLabel.textColor;
    detTextLabel.backgroundColor = [UIColor clearColor];
    detTextLabel.tag = 3;
    detTextLabel.numberOfLines = 2;
    [cell.contentView addSubview:detTextLabel];
    cell.detailTextLabel.textColor = [UIColor clearColor];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.tag = 4;
    [cell.contentView addSubview:imageView];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (UITableViewCell *)cellWithTableView:(UITableView*)tableView title:(NSString*)title subtitle:(NSString*)subtitle time:(NSString*)time image:(NSString*)image
{
    UITableViewCell *cell = [self cellWithTableView:tableView];
    
    UILabel *timeLabel = (UILabel*)[cell viewWithTag:1];
    UILabel *textLabel = (UILabel*)[cell viewWithTag:2];
    UILabel *detTextLabel = (UILabel*)[cell viewWithTag:3];
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:4];
    
    // Update time label
    
    CGSize timeSize;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
        timeLabel.text = time;
        timeSize = [time sizeWithFont:timeLabel.font];
    } else {
        NSAttributedString *timeAttString = [YTHelper formatDateAttr:time size:12 color:[UIColor blueColor]];
        timeLabel.attributedText = timeAttString;
        timeSize = [timeAttString size];
    }
    CGFloat timeWidth = timeSize.width + 5;
    timeLabel.frame = CGRectMake(cell.bounds.size.width - timeWidth - 30, 5, timeWidth, timeSize.height);
    
    // Update title label
    
    CGFloat textFontSize = cell.textLabel.font.pointSize;
    textLabel.frame= CGRectMake(78, 2, cell.frame.size.width - timeWidth - 30 - 10 - 78, 21);
    textLabel.font = [UIFont boldSystemFontOfSize:textFontSize];
    textLabel.text = title;
    cell.textLabel.text = @" ";
    
    // Update subtitle label
    
    detTextLabel.frame= CGRectMake(78, 23, cell.frame.size.width - 30 -  78, 32);
    detTextLabel.text = [NSString stringWithFormat:@"%@\n ", subtitle];
    
    cell.detailTextLabel.text = @" ";
    
    imageView.frame = CGRectMake(5, (cell.frame.size.height - 18) / 2, 18, 18);
    if (image) {
        imageView.image = [YTHelper imageNamed:image];
        imageView.hidden = NO;
    } else {
        imageView.image = nil;
        imageView.hidden = YES;
    }
    
    [textLabel removeFromSuperview];
    [cell.contentView addSubview:textLabel];
    
    [timeLabel removeFromSuperview];
    [cell.contentView addSubview:timeLabel];
    
    [detTextLabel removeFromSuperview];
    [cell.contentView addSubview:detTextLabel];
    
    [imageView removeFromSuperview];
    [cell.contentView addSubview:imageView];
    
    for (UIView *view in cell.contentView.subviews) {
        view.alpha = 1;
    }
    
    return cell;
}

@end
