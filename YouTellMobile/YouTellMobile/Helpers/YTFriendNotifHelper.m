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
@property (strong, nonatomic) UIAlertView* alert;
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
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(self.alert) //showing an alert? do nothing
            return;
    
        if (!self.notifiedFriendship) //we aren't interested a specific friend, just an update from main gab etc.
            return;
        
        
        self.friend = [YTFriend findByID:self.notifiedFriendship];
    
        if (!self.friend) { //lost the friend, or  wrong user
            return;
        }
    
        [[Mixpanel sharedInstance] track:@"Received A New Friend Notification"];
    
        NSString *messageFormat = NSLocalizedString(@"%@ just joined Backdoor! Send them a message!", nil);
        NSString *name = self.friend.name;
        NSString *message = [NSString stringWithFormat:messageFormat, name];
    
        self.alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
        self.alert.delegate = self;
        [self.alert show]; //let the user decide. alert = true && self.notifiedFrendship = true
    }];
}

- (void)handleNotification:(NSDictionary *)data
{   
    NSString *friendship_id = data[@"friendship_id"];
    if (!friendship_id) {
        return;
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(self.alert) //if we are currently showing an alert about friends..do nothing.
            return;
        
        if(self.notifiedFriendship) //if we are currently waiting to get friend info..do nothing.
            return;
    
        self.notifiedFriendship = friendship_id;
    
        [YTFriends updateFriendsOfType:YTFriendType]; //kick off friend info. self.alert = nil BUT self.notifiedFriendship != nil
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.alert = nil;
    self.notifiedFriendship = nil;
    
    if (buttonIndex == alertView.cancelButtonIndex) {
        [[Mixpanel sharedInstance] track:@"Declined To Send A Message To A New Friend"];
        return;
    }
    
    [[Mixpanel sharedInstance] track:@"Agreed To Send A Message To A New Friend"];

    [YTViewHelper showGabWithFriend:self.friend animated:YES];
}

@end
