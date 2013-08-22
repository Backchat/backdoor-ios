//
//  YTFriend.h
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface YTFriend : NSManagedObject
@property (nonatomic) NSString* name;
@property (nonatomic) NSNumber* id;
@property (nonatomic) NSNumber* featured_id;
@property (nonatomic) NSString* type;
@property (nonatomic) NSString* value;
@property (nonatomic) NSString* source;

@property (nonatomic, strong, readonly) NSString* avatarUrl;
@property (nonatomic, assign, readonly) bool isFriend;

+ (YTFriend*)findByID:(id)ID;
+ (YTFriend*)updateFriend:(id)JSON;
@end
extern NSString* const YTFeaturedFriendType;
extern NSString* const YTFriendType;
