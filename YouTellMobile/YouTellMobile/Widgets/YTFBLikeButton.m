//
//  YTFBLikeButton.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <FacebookSDK.h>
#import <Facebook.h>

#import "YTApiHelper.h"
#import "YTFBLikeButton.h"
#import "YTConfig.h"
#import "YTFBHelper.h"

@implementation YTFBLikeButton


- (void)load
{
    self.delegate = self;
    self.href = [NSURL URLWithString:CONFIG_FB_LIKE_URL];
    self.scrollView.bounces = NO;
    self.scrollView.scrollEnabled = NO;

    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://capricalabs.com:7564/fblikebutton.html"]]];
    
}


- (void)didObserveFacebookEvent:(NSString*)event
{
    if (![event isEqualToString:@"like"]) {
        return;
    }
    
    [YTApiHelper getFreeCluesWithReason:@"freeclues"];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.absoluteString hasPrefix:CONFIG_URL]) {
        return YES;
    }
    
    if ([request.URL.host isEqual:self.href.host]) {
        return YES;
    }
    
    if ([request.URL.scheme isEqualToString:@"about"]) {
        return YES;
    }
    
    if ([request.URL.scheme isEqualToString:@"event"]) {
        [self didObserveFacebookEvent:request.URL.resourceSpecifier];
        return NO;
    }
    
    if (![request.URL.host hasSuffix:@"facebook.com"] && ![request.URL.host hasSuffix:@"fbcdn.net"]) {
        return NO;
    }
    
    if ([request.URL.path isEqualToString:@"/dialog/plugin.optin"] ||
             ([request.URL.path isEqualToString:@"/plugins/like/connect"] && [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] hasPrefix:@"lsd"])) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"You need to log-in using your Facebook account", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    
     return YES;
}

@end
