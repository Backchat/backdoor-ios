//
//  YTContacts.h
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTContact.h"
#import "YTFriends.h"

@interface YTContacts : NSObject
@property (assign, readonly) int count;
- (YTContact*) contactAtIndex:(int)index;
- (id)init;
- (id)initWithArray:(NSArray*)array;
- (id)initWithContacts:(YTContacts*)contacts excludingFriends:(YTFriends*)friends;
- (id)initWithContacts:(YTContacts*)contacts withFilter:(NSString*)filter;
@end
