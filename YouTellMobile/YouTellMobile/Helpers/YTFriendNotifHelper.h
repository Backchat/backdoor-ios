//
//  YTFriendNotifHelper.h
//  Backdoor
//
//  Created by Łukasz S on 7/28/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTViewHelper.h"

@interface YTFriendNotifHelper : YTViewHelper <UIAlertViewDelegate>

@property (strong, nonatomic) NSDictionary *contact;

+ (YTFriendNotifHelper*)sharedInstance;
- (void)handleNotification:(NSDictionary *)data;

@end
