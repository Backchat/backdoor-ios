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
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident];
        cell.textLabel.hidden = YES;
        cell.detailTextLabel.hidden = YES;

        NSLog(@"%@", NSStringFromCGRect(cell.frame));
        
        [self addCellSubViewsToView:cell.contentView];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.backgroundView = [UIView new];
        cell.backgroundView.backgroundColor = [UIColor clearColor];
    }
    
    
    return cell;
}

- (void)addCellSubViewsToView:(UIView*)view
{    
    UIImageView *avatarView = [[UIImageView alloc] init];
    avatarView.tag = 5;
    avatarView.layer.cornerRadius = 5;
    avatarView.layer.masksToBounds = YES;
    [view addSubview:avatarView];
    
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.font = [UIFont systemFontOfSize:12];
    timeLabel.textColor = [UIColor blueColor];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.tag = 1;

    [view addSubview:timeLabel];
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textLabel.font = [UIFont boldSystemFontOfSize:17];
    textLabel.tag = 2;
    textLabel.backgroundColor = [UIColor clearColor];
    [view addSubview:textLabel];
    
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
    
    int width = 320;
    
    avatarView.frame = CGRectMake(26, 7, 45, 45);
    
    timeLabel.frame = CGRectMake(78, 5, width - 78 - 12, 16);

    detTextLabel.frame= CGRectMake(78, 23, width - 78 - 12, 32);
    
    imageView.frame = CGRectMake(5, (60 - 18) / 2, 18, 18);

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
    else
        cell.backgroundView.backgroundColor = [UIColor clearColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
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

    if(time && time.length > 0) {
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
        
        timeLabel.hidden = NO;
    }
    else
        timeLabel.hidden = YES;

    // Update title label
    textLabel.frame= CGRectMake(78, 2, 320 - timeWidth - 12 - 78, 21);
    textLabel.text = title;
    
    // Update subtitle label
    
    detTextLabel.text = [NSString stringWithFormat:@"%@\n ", subtitle];
    
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

- (UITableViewCell*) cellWithGab:(YTGab*)gab andTableView:(UITableView*)tableView;
{
    
    BOOL read = [gab.unread_count isEqualToNumber:@0];
    NSString *title = [gab gabTitle];
    NSString *subtitle = gab.content_summary;
    NSString *time = [YTHelper formatDate:gab.updated_at];
    NSString *image = read ? nil : @"newgab2";
    NSString* avatar = gab.related_avatar;
    
    return [self cellWithTableView:tableView
                             title:title
                          subtitle:subtitle
                              time:time
                             image:image
                            avatar:avatar
                  placeHolderImage:[YTHelper imageNamed:@"avatar6"]
                   backgroundColor:[UIColor whiteColor]];
}

- (UITableViewCell*) cellForInvite:(UITableView*)tableView
{
    NSString *title = NSLocalizedString(@"Invite", nil);
    NSString *subtitle = NSLocalizedString(@"Invite your friends to Backdoor", nil);
    NSString *time = @"";
    NSString *image = @"invite_gab_cell_icon";
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView title:title subtitle:subtitle time:time image:@""
                                                                          avatar:image placeHolderImage:nil
                                                                 backgroundColor:[UIColor whiteColor]];
    
    return cell;
}

- (UITableViewCell *)cellForShare:(UITableView *)tableView
{
    NSString *title = NSLocalizedString(@"Share", nil);
    NSString *subtitle = NSLocalizedString(@"Tap me to get more BD friends.", nil);
    NSString *time = @"";
    NSString *image = @"https://s3.amazonaws.com/backdoor_images/icon_114x114.png";
    
    UITableViewCell *cell = [[YTMainViewHelper sharedInstance] cellWithTableView:tableView
                                                                           title:title
                                                                        subtitle:subtitle
                                                                            time:time
                                                                           image:nil
                                                                          avatar:image
                                                                placeHolderImage:nil
                                                                 backgroundColor:[UIColor whiteColor]];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}


@end
