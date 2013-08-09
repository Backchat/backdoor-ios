//
//  YTFriend.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTFriend.h"

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
    return [self.source isEqualToString:@"friend"];
}

@end
