//
//  YTFriendNotifHelper.m
//  Backdoor
//
//  Created by Łukasz S on 7/28/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTFriendNotifHelper.h"
#import "YTAppDelegate.h"
#import "YTApiHelper.h"
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
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    NSString *receiverEmail = data[@"receiver_email"];
    if (!receiverEmail || ![receiverEmail isEqualToString:delegate.userInfo[@"email"]]) {
        return;
    }
    
    [YTApiHelper getFriends:^(id JSON) {
        
        self.contact = [[YTContactHelper sharedInstance] findContactWithType:data[@"provider"] value:data[@"social_id"]];
        
        if (!self.contact) {
            return;
        }
        
        [[Mixpanel sharedInstance] track:@"Received A New Friend Notification"];
        
        NSString *messageFormat = NSLocalizedString(@"%@ just joined Backdoor! Send him a message!", nil);
        NSString *name = self.contact[@"name"];
        NSString *message = [NSString stringWithFormat:messageFormat, name];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
        alert.delegate = self;
        [alert show];
        
    }];
    

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [[Mixpanel sharedInstance] track:@"Declined To Send A Message To A New Friend"];
        return;
    }
    
    [[Mixpanel sharedInstance] track:@"Agreed To Send A Message To A New Friend"];

    [YTViewHelper showGabWithReceiver:self.contact];
}

@end
