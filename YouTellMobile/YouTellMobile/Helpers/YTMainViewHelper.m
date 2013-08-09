//
//  YTMainViewHelper.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTMainViewHelper.h"
#import "YTHelper.h"
#import <SDWebImage/UIImageView+WebCache.h>
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
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident];
    cell.textLabel.hidden = YES;
    cell.detailTextLabel.hidden = YES;
    
    [self addCellSubViewsToView:cell.contentView];
        
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.backgroundView = [UIView new];
    cell.backgroundView.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)addCellSubViewsToView:(UIView*)view
{    
    UIImageView *avatarView = [[UIImageView alloc] init];
    avatarView.tag = 5;
    avatarView.layer.cornerRadius = 5;
    avatarView.layer.masksToBounds = YES;
    avatarView.frame = CGRectMake(26, 7, 45, 45);
    [view addSubview:avatarView];
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textLabel.font = [UIFont boldSystemFontOfSize:17];
    textLabel.tag = 2;
    textLabel.backgroundColor = [UIColor clearColor];
    [view addSubview:textLabel];
    
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.font = [UIFont systemFontOfSize:12];
    timeLabel.textColor = [UIColor blueColor];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.tag = 1;
    
    [view addSubview:timeLabel];
    
    UILabel *detTextLabel = [[UILabel alloc] init];
    detTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    detTextLabel.font = [UIFont systemFontOfSize:13];
    detTextLabel.backgroundColor = [UIColor clearColor];
    detTextLabel.tag = 3;
    detTextLabel.numberOfLines = 2;
    [view addSubview:detTextLabel];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.tag = 4;
    [view addSubview:imageView];

}

- (UITableViewCell *)cellWithTableView:(UITableView*)tableView title:(NSString*)title subtitle:(NSString*)subtitle time:(NSString*)time
                                 image:(NSString*)image avatar:(NSString*)avatar placeHolderImage:(UIImage*)placeHolderImage backgroundColor:(UIColor*)backgroundColor
{
    UITableViewCell *cell = [self cellWithTableView:tableView];
    [self setCellValuesInView:cell title:title subtitle:subtitle time:time image:image avatar:avatar placeHolderImage:placeHolderImage];
    
    for (UIView *view in cell.contentView.subviews) {
        view.alpha = 1;
    }
    
    if(backgroundColor)
        cell.backgroundView.backgroundColor = backgroundColor;
    
    return cell;
}

- (void)setCellValuesInView:(UIView *)cell title:(NSString *)title subtitle:(NSString *)subtitle time:(NSString *)time image:(NSString *)image
                     avatar:(NSString*)avatar placeHolderImage:(UIImage*)placeHolderImage
{
    UILabel *timeLabel = (UILabel*)[cell viewWithTag:1];
    UILabel *textLabel = (UILabel*)[cell viewWithTag:2];
    UILabel *detTextLabel = (UILabel*)[cell viewWithTag:3];
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:4];
    UIImageView* avatarView = (UIImageView*)[cell viewWithTag:5];

    // Update time label
    
    CGFloat timeWidth = 0;

    if(time) {
        CGSize timeSize;

        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
            timeLabel.text = time;
            timeSize = [time sizeWithFont:timeLabel.font];
        } else {
            NSAttributedString *timeAttString = [YTHelper formatDateAttr:time size:12 color:[UIColor blueColor]];
            timeLabel.attributedText = timeAttString;
            timeSize = [timeAttString size];
            timeSize.width = timeSize.width + 2;
        }
        timeWidth = timeSize.width + 5;
        timeLabel.frame = CGRectMake(cell.bounds.size.width - timeWidth - 30, 5, timeWidth, timeSize.height);
    }
    // Update title label
    
    textLabel.frame= CGRectMake(78, 2, cell.frame.size.width - timeWidth - 30 - 10 - 78, 21);
    textLabel.text = title;
    
    // Update subtitle label
    
    detTextLabel.frame= CGRectMake(78, 23, cell.frame.size.width - 30 -  78, 32);
    detTextLabel.text = [NSString stringWithFormat:@"%@\n ", subtitle];
        
    imageView.frame = CGRectMake(5, (cell.frame.size.height - 18) / 2, 18, 18);
    if (image && image.length > 0) {
        imageView.image = [YTHelper imageNamed:image];
        imageView.hidden = NO;
    } else {
        imageView.image = nil;
        imageView.hidden = YES;
    }
        
    if (avatar && avatar.length > 0) {
        if([avatar rangeOfString:@"http"].location == NSNotFound) {
            avatarView.image = [YTHelper imageNamed:avatar];
        }
        else {
            [avatarView setImageWithURL:[NSURL URLWithString:avatar] placeholderImage:placeHolderImage options:SDWebImageRefreshCached];
        }
        avatarView.hidden = NO;
    } else {
        if(placeHolderImage) {
            avatarView.image = placeHolderImage;
            avatarView.hidden = NO;
        }
        else {
            avatarView.image = nil;
            avatarView.hidden = YES;
        }
    }
}

@end
