//
//  YTInviteSettingsViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "YTInviteSettingsViewController.h"
#import "YTAppDelegate.h"
#import "YTFBHelper.h"
#import "YTGPPHelper.h"
#import "YTFBLikeButton.h"
#import "YTTwitterHelper.h"
#import "YTModelHelper.h"

@interface YTInviteSettingsViewController ()

@end

@implementation YTInviteSettingsViewController


- (void)viewDidLoad
{
    NSString *title;
    NSString *labelText;
    NSInteger labelSize;
    
    if ([YTModelHelper userHasShared]) {
        title = NSLocalizedString(@"Share with Friends", nil);
        labelText = NSLocalizedString(@"Share with Friends", nil);
        labelSize = 16;
    } else {
        title = NSLocalizedString(@"Free Clues", nil);
        labelText = NSLocalizedString(@"Earn 9 additional free clues by posting, liking\nor tweeting about Backdoor", nil);
        labelSize = 14;
    }
    
    self.title = title;
    
    //YTAppDelegate *delegate = [YTAppDelegate current];
    
    /*
    if ([delegate.userInfo[@"provider"] isEqualToString:@"facebook"]) {
        self.tableData = @[
            @[
                @[@"icon_facebook2.png", NSLocalizedString(@"Share on Facebook", nil), @"showFBShare"],
                @[@"icon_facebook2.png", NSLocalizedString(@"Invite on Facebook", nil), @"showFBInvite"],
            ]
        ];
    } else {
        self.tableData = @[
            @[
                @[@"", NSLocalizedString(@"Share on Google+", nil), @"showGPPShare"],
            ]
        ];
    }
     */
    
    [super viewDidLoad];
    
    CGFloat width = [YTAppDelegate current].window.bounds.size.width;
    CGFloat base_y = 0;
    
    UILabel *label1 = [[UILabel alloc] init];
    label1.text = labelText;
    label1.font = [UIFont boldSystemFontOfSize:labelSize];
    label1.textColor = [UIColor colorWithRed:0x24/255.0 green:0x6d/255.0 blue:0x00/255.0 alpha:1];
    label1.textColor = [UIColor blackColor];
    label1.numberOfLines = 3;
    label1.textAlignment = NSTextAlignmentCenter;
    label1.backgroundColor = [UIColor clearColor];
    [label1 sizeToFit];
    CGRect frame = label1.frame;
    frame.origin.y = (base_y += 30);
    frame.origin.x = (width - frame.size.width) / 2;
    label1.frame = frame;
    
    
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [shareButton setTitle:NSLocalizedString(@"Post on Facebook", nil) forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    shareButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [shareButton sizeToFit];
    [shareButton setBackgroundImage:[[UIImage imageNamed:@"fc_facebook_inactive.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10,10,10,10)] forState:UIControlStateNormal];
    [shareButton setBackgroundImage:[[UIImage imageNamed:@"fc_facebook_active.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10,10,10,10)] forState:UIControlStateNormal];

    [shareButton addTarget:self action:@selector(showFBShare) forControlEvents:UIControlEventTouchUpInside];
    frame = shareButton.frame;
    frame.size.width = 250;
    frame.size.height = 50;
    frame.origin.y = (base_y += 70);
    frame.origin.x = (width - frame.size.width) / 2;
    shareButton.frame = frame;
    
    /*
    UILabel *label3 = [[UILabel alloc] init];
    label3.text = NSLocalizedString(@"- OR -", nil);
    label3.font = [UIFont systemFontOfSize:13];
    label3.textColor = [UIColor blackColor];
    label3.backgroundColor = [UIColor clearColor];
    [label3 sizeToFit];
    frame = label3.frame;
    frame.origin.y = (base_y += 55);
    frame.origin.x = (width - frame.size.width) / 2;
    label3.frame = frame;
     */
    
    /*
    base_y += 55;
    YTFBLikeButton *likeButton = [YTFBLikeButton new];
    frame.size.height = 34;
    frame.size.width = 150;
    frame.origin.x = (width - frame.size.width) / 2;
    frame.origin.y = (base_y);
    likeButton.frame = frame;
    likeButton.layer.borderColor = [[UIColor grayColor] CGColor];
    likeButton.layer.borderWidth = 1;
    likeButton.layer.cornerRadius = 5;
    likeButton.layer.masksToBounds = YES;
    [likeButton load];
    */

    /*
    UILabel *label2 = [[UILabel alloc] init];
    label2.text = NSLocalizedString(@"- OR -", nil);
    label2.font = [UIFont systemFontOfSize:13];
    label2.textColor = [UIColor blackColor];
    label2.backgroundColor = [UIColor clearColor];
    [label2 sizeToFit];
    frame = label2.frame;
    frame.origin.y = (base_y += 43);
    frame.origin.x = (width - frame.size.width) / 2;
    label2.frame = frame;
      */
    
    
    UIButton *tweetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tweetButton setTitle:NSLocalizedString(@"Tweet about Backdoor", nil) forState:UIControlStateNormal];
    [tweetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    tweetButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [tweetButton sizeToFit];
    [tweetButton setBackgroundImage:[[UIImage imageNamed:@"fc_twitter_inactive.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forState:UIControlStateNormal];
    [tweetButton setBackgroundImage:[[UIImage imageNamed:@"fc_twitter_active.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forState:UIControlStateHighlighted];

    [tweetButton addTarget:self action:@selector(showTweetSheet) forControlEvents:UIControlEventTouchUpInside];
    frame = tweetButton.frame;
    frame.size.width = 250;
    frame.size.height = 50;
    frame.origin.y = (base_y += 70);
    frame.origin.x = (width - frame.size.width) / 2;
    tweetButton.frame = frame;
    
    UIButton *gppButton = [[UIButton alloc] init];
    [gppButton setTitle:NSLocalizedString(@"Share on Google+", nil) forState:UIControlStateNormal];
    [gppButton setBackgroundImage:[[UIImage imageNamed:@"fc_gpp_inactive.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)] forState:UIControlStateNormal];
    [gppButton setBackgroundImage:[[UIImage imageNamed:@"fc_gpp_active.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)] forState:UIControlStateHighlighted];
    [gppButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    gppButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [gppButton addTarget:self action:@selector(showGPPShare) forControlEvents:UIControlEventTouchUpInside];
    frame = gppButton.frame;
    frame.size.width = 250;
    frame.size.height = 50;
    frame.origin.y = (base_y += 70);
    frame.origin.x = (width - frame.size.width) / 2;
    gppButton.frame = frame;
    
    [self.view addSubview:label1];
    [self.view addSubview:shareButton];
    //[self.view addSubview:label3];
    //[self.view addSubview:likeButton];
    //[self.view addSubview:label2];
    [self.view addSubview:tweetButton];
    [self.view addSubview:gppButton];

}

- (void)showFBShare
{
    [YTFBHelper presentFeedDialog];
}

- (void)showFBInvite
{
    [YTFBHelper presentRequestDialogWithContact:nil complete:nil];
}

- (void)showGPPShare
{
    [[YTGPPHelper sharedInstance] presentShareDialog];
}

- (void)showTweetSheet
{
    [[YTTwitterHelper sharedInstance] showTweetSheet:self];
}

@end
