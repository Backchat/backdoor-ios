//
//  YTFriendNotifHelper.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTFriendNotifHelper.h"
#import "YTAppDelegate.h"
#import "YTApiHelper.h"
#import "YTFriends.h"

#import "YTViewHelper.h"

#import <Mixpanel.h>

@interface YTFriendNotifHelper ()
@property (strong, nonatomic) YTFriend *friend;
@property (strong, nonatomic) NSString* notifiedFriendship;
@end

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

- (id)init {
    if(self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFriends:)
                                                     name:YTFriendNotification object:nil];
    }
    return self;
}

- (void)updateFriends:(NSNotification*)note
{
    self.friend = nil;
    
    if (self.notifiedFriendship) {
        self.friend = [YTFriend findByID:self.notifiedFriendship];
        self.notifiedFriendship = nil;
    }
    
    if (!self.friend) {
        return;
    }
    
    [[Mixpanel sharedInstance] track:@"Received A New Friend Notification"];
    
    NSString *messageFormat = NSLocalizedString(@"%@ just joined Backdoor! Send him a message!", nil);
    NSString *name = self.friend.name;
    NSString *message = [NSString stringWithFormat:messageFormat, name];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
    alert.delegate = self;
    [alert show];
}

- (void)handleNotification:(NSDictionary *)data
{   
    NSString *friendship_id = data[@"friendship_id"];
    if (!friendship_id) {
        return;
    }
    
    self.notifiedFriendship = friendship_id;
    
    [YTFriends updateFriendsOfType:YTFriendType];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [[Mixpanel sharedInstance] track:@"Declined To Send A Message To A New Friend"];
        return;
    }
    
    [[Mixpanel sharedInstance] track:@"Agreed To Send A Message To A New Friend"];

    [YTViewHelper showGabWithFriend:self.friend];
}

@end
