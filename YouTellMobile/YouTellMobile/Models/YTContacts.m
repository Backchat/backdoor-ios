//
//  YTContacts.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTContacts.h"

@interface YTContacts ()
@property (nonatomic, retain) NSMutableArray* contacts;
@end

@implementation YTContacts
- (int)count
{
    return self.contacts.count;
}

- (YTContact*) contactAtIndex:(int)index
{
    return [self.contacts objectAtIndex:index];
}

- (id)init
{
    if(self = [super init]) {
        self.contacts = [NSMutableArray new];
    }
    return self;
}

- (id)initWithArray:(NSArray*)array
{
    if(self = [super init]) {
        self.contacts = [NSMutableArray arrayWithArray:array];
    }
    return self;
}

- (id)initWithContacts:(YTContacts*)contacts excludingFriends:(YTFriends*)friends
{
    if(self = [super init]) {
        self.contacts = [NSMutableArray new];
        for(YTContact* c in contacts.contacts) {
            if(![friends findFriendByValue:c.value])
                [self.contacts addObject:c];
        }
    }
    
    return self;
}

- (id)initWithContacts:(YTContacts*)contacts withFilter:(NSString*)filter
{
    if(self = [super init]) {
        if(filter && filter.length != 0) {
            self.contacts = [NSMutableArray new];
            for(YTContact* c in contacts.contacts) {
                if([c.name rangeOfString:filter options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch].location != NSNotFound)
                    [self.contacts addObject:c];
            }
        }
        else {
            self.contacts = [NSMutableArray arrayWithArray:contacts.contacts];
        }
    }
    
    return self;
}

@end
