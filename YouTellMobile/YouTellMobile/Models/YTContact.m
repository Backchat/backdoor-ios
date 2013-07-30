//
//  YTContact.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTContact.h"

@implementation YTContact

@synthesize first_name;
@synthesize last_name;
@synthesize value;

- (NSString*) name
{
    return [NSString stringWithFormat:@"%@ %@", self.first_name, self.last_name];
}

- (NSString*) localizedType
{
    if([self.type isEqualToString:@"facebook"])
        return NSLocalizedString(@"Facebook", nil);
    else
        return @"";
}

//TODO we really should merge this with YTFriend
- (NSString*) avatarUrl
{
    if ([self.type isEqualToString:@"facebook"]) {
        return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", self.value];
    }
    else if([self.type isEqualToString:@"gpp"]) {
        return [NSString stringWithFormat:@"https://profiles.google.com/s2/photos/profile/%@?sz=50", self.value];
    }
    else
        return nil;
}

@synthesize type;

@end
