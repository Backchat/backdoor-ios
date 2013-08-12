//
//  YTFriendNotifHelper.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTViewHelper.h"
#import "YTFriend.h"

@interface YTFriendNotifHelper : YTViewHelper <UIAlertViewDelegate>

+ (YTFriendNotifHelper*)sharedInstance;
- (void)handleNotification:(NSDictionary *)data;

@end
