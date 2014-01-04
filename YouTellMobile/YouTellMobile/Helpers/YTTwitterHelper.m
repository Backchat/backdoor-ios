//
//  YTTwitterHelper.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Twitter/Twitter.h>
#import <Mixpanel.h>

#import "YTTwitterHelper.h"
#import "YTApiHelper.h"
#import "YTConfig.h"

@implementation YTTwitterHelper

+ (YTTwitterHelper*)sharedInstance
{
    static YTTwitterHelper *instance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        instance = [YTTwitterHelper new];
    });
    return instance;
}

- (void)showTweetSheet:(UIViewController*)controller;
{
    if ([TWTweetComposeViewController canSendTweet]) {
        TWTweetComposeViewController *sheet = [[TWTweetComposeViewController alloc] init];
        NSString* shortenedLink = CONFIG_SHARE_URL;
        [sheet setInitialText:[NSString stringWithFormat:NSLocalizedString(@"Message me with Backchat. %@ #backchatme",
                                                                           nil), shortenedLink]];
        sheet.completionHandler = ^(TWTweetComposeViewControllerResult result) {
            [self completionHandler:result];
        };
        self.parentController = controller;
        [controller presentModalViewController:sheet animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"You can't send a tweet. Make sure you have working internet connection and at least one Twitter account configured", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)completionHandler:(TWTweetComposeViewControllerResult)result {
    [self.parentController dismissModalViewControllerAnimated:YES];

    if (result != TWTweetComposeViewControllerResultDone) {
        return;
    }
    
    [YTApiHelper getFreeCluesWithReason:@"tweet"];
    [[Mixpanel sharedInstance] track:@"Tweeted About Backchat"];
}

@end
