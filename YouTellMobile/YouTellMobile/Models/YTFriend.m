//
//  YTFriend.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTFriend.h"
#import "YTAppDelegate.h"

@implementation YTFriend
@dynamic name;
@dynamic id;
@dynamic featured_id;
@dynamic type;
@dynamic source;
@dynamic value;

- (NSString*) avatarUrl
{
    if ([self.type isEqualToString:@"facebook"]) {
        return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=90&height=90", self.value];
    }
    else if([self.type isEqualToString:@"gpp"]) {
        return [NSString stringWithFormat:@"https://profiles.google.com/s2/photos/profile/%@?sz=90", self.value];
    }
    else
        return nil;
}

- (bool)isFriend
{
    return [self.source isEqualToString:YTFriendType];
}

+ (YTFriend*)updateFriend:(id)friendJSON
{
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    YTFriend *friend = [YTFriend findByID:friendJSON[@"id"]];
    if(friend == nil)
        friend = [NSEntityDescription insertNewObjectForEntityForName:@"Contacts" inManagedObjectContext:context];

    [friend setValue:friendJSON[@"first_name"] forKey:@"first_name"];
    [friend setValue:friendJSON[@"last_name"] forKey:@"last_name"];
    
    NSString* type = friendJSON[@"type"];
    if(!type)
        type = friendJSON[@"provider"];
    [friend setValue:type forKey:@"type"];
    
    NSString* value = friendJSON[@"value"];
    if(!value)
        value = friendJSON[@"social_id"];
    [friend setValue:value forKey:@"value"];
    
    [friend setValue:friendJSON[@"friend_id"] forKey:@"friend_id"];
    [friend setValue:friendJSON[@"id"] forKey:@"id"];
    [friend setValue:friendJSON[@"featured_id"] forKey:@"featured_id"];
    
    NSString* source = [friendJSON valueForKey:@"source"];
    if(source) {
        if([source isEqualToString:@"friend"])
            source = YTFriendType;
        else
            source = YTFeaturedFriendType;
    }
    else {
        if([friendJSON valueForKey:@"id"]) {
            source = YTFriendType;
        }
        else if([friendJSON valueForKey:@"featured_id"]) {
            source = YTFeaturedFriendType;
        }
    }
    
    [friend setValue:source forKey:@"source"];
    
    NSString* full_name = friendJSON[@"name"];
    if(!full_name) {
        full_name = [NSString stringWithFormat:@"%@ %@", friendJSON[@"first_name"], friendJSON[@"last_name"]];
    }
    
    [friend setValue:full_name forKey:@"name"];
    
    return friend;
}

+ (YTFriend*)findByID:(id)ID
{
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:@"Contacts"];
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    
    request.predicate = [NSPredicate predicateWithFormat:@"(id = %@)", ID];
    
    NSError *error;
    NSArray* objects = [context executeFetchRequest:request error:&error];
    if ([objects count] == 0) {
        return nil;
    }
    return objects[0];
}

@end

NSString* const YTFeaturedFriendType = @"YTFeaturedFriendType";
NSString* const YTFriendType = @"YTFriendType";
