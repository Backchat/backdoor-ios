//
//  YTFriendsHelper.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTFriends.h"
#import "YTAppDelegate.h"

@interface YTFriends ()
{
}
@property (nonatomic, retain) NSFetchRequest* request;
@property (nonatomic, retain) NSArray* items;
@end

static bool validData = false;

@implementation YTFriends

- (void)findContactsWithString:(NSString *)string andSource:(NSString*)source
{
    self.request = [[NSFetchRequest alloc] initWithEntityName:@"Contacts"];
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    
    if (string && ![string isEqualToString:@""]) {
        self.request.predicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) AND (source = %@)", string, source];
    }
    else {
        self.request.predicate = [NSPredicate predicateWithFormat:@"(source = %@)", source];
    }
    
    NSSortDescriptor *lastNameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"first_name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    self.request.sortDescriptors = @[lastNameSortDescriptor, nameSortDescriptor];
    
    NSError *error;
    self.items = [context executeFetchRequest:self.request error:&error];
}

- (id)initWithFeaturedUsers
{
    if(self = [super init]) {
        [self findContactsWithString:@"" andSource:YTFeaturedFriendType];
    }
    
    return self;
}

- (id)initWithSearchStringRandomized:(NSString*)search
{
    if(self = [super init]) {
        [self findContactsWithString:search andSource:YTFriendType];
        NSMutableArray* newArray = [NSMutableArray arrayWithArray:self.items];
        NSUInteger count = [newArray count];
        for (NSUInteger i = 0; i < count; ++i) {
            // Select a random element between i and end of array to swap with.
            NSInteger nElements = count - i;
            NSInteger n = (arc4random() % nElements) + i;
            [newArray exchangeObjectAtIndex:i withObjectAtIndex:n];
        }
        self.items = newArray;
    }
    return self;
}

- (YTFriend*) findFriendByValue:(NSString*)value
{
    //TODO use query?
    for(YTFriend* f in self.items) {
        if([f.value isEqualToString:value])
            return f;
    }
    
    return nil;
}

- (id)initWithSearchString:(NSString*)search
{
    if(self = [super init]) {
        [self findContactsWithString:search andSource:YTFriendType];
    }
    return self;
}

- (id)init
{
    return [self initWithSearchString:@""];
}

- (int)count
{
    return self.items.count;
}

- (YTFriend*) friendAtIndex:(int)index
{
    return [self.items objectAtIndex:index];
}

- (bool)hasValidData
{
    return validData;
}

+ (void)clearWithSource:(NSString *)source
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Contacts"];
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    request.predicate = [NSPredicate predicateWithFormat:@"(source = %@)", source];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    
    for (NSManagedObject *object in objects) {
        [context deleteObject:object];
    }
    
}

+ (void)parseFriendsOfType:(NSString *)type withJSON:(id)JSON
{
    if(type == YTFriendType)
        validData = true;
    
    [YTFriends clearWithSource:type];

    for (NSDictionary *u in JSON) {
        [YTFriend addFriend:u];
    }
    
    NSString* notificationName = nil;
    
    if (type == YTFeaturedFriendType) {
        notificationName = YTFeaturedFriendNotification;
    }
    else {
        notificationName = YTFriendNotification;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                        object:nil];
}

@end

NSString* const YTFriendNotification = @"YTFriendNotification";
NSString* const YTFeaturedFriendNotification = @"YTFeaturedFriendNotification";
