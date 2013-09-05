//
//  YTFriends.h
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/NSManagedObject.h>
#import "YTFriend.h"
#import <AFNetworking.h>

@interface YTFriends : NSObject
- (id)initWithSearchString:(NSString*)search;
- (id)initWithSearchStringRandomized:(NSString*)search;
- (id)init;
- (id)initWithFeaturedUsers;
- (int) count;
- (YTFriend*) friendAtIndex:(int)index;
- (YTFriend*) findFriendByValue:(NSString*)value;
+ (bool)hasValidData;
+ (void)updateFriendsOfType:(NSString*)type;
+ (AFHTTPRequestOperation*)updateFriendsOfTypeNetworkingOperation:(NSString*)type;
@end

extern NSString* const YTFriendNotification;
extern NSString* const YTFeaturedFriendNotification;