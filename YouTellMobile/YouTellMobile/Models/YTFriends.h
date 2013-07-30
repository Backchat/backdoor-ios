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

@interface YTFriends : NSObject
- (id)initWithSearchString:(NSString*)search;
- (id)initWithSearchStringRandomized:(NSString*)search;
- (id)init;
- (id)initWithFeaturedUsers;
- (int) count;
- (YTFriend*) friendAtIndex:(int)index;
- (YTFriend*) findFriendByValue:(NSString*)value;
@end
