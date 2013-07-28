//
//  YTFriendNotifHelper.m
//  Backdoor
//
//  Created by Łukasz S on 7/28/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTFriendNotifHelper.h"
#import "YTContactHelper.h"

#import "YTViewHelper.h"

#import <Mixpanel.h>

@implementation YTFriendNotifHelper

+ (YTFriendNotifHelper*)sharedInstance
{
    static YTFriendNotifHelper *instance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        instance = [YTFriendNotifHelper new];
    });
    return instance;
}

- (void)handleNotification:(NSDictionary *)data
{
    [[Mixpanel sharedInstance] track:@"Received A New Friend Notification"];

    NSString *messageFormat = NSLocalizedString(@"%@ just joined Backdoor! Send him a message!", nil);
    NSString *name = data[@"name"];
    NSString *message = [NSString stringWithFormat:messageFormat, name];
    
    self.data = data;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
    alert.delegate = self;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [[Mixpanel sharedInstance] track:@"Declined To Send A Message To A New Friend"];
        return;
    }
    
    [[Mixpanel sharedInstance] track:@"Agreed To Send A Message To A New Friend"];
    
    NSDictionary *contact = [[YTContactHelper sharedInstance] findContactWithType:self.data[@"provider"] value:self.data[@"social_id"]];
    
    if (!contact) {
        return;
    }
    
    [YTViewHelper showGabWithReceiver:contact];    
}

@end
