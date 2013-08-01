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
@synthesize phone_number;
@synthesize type;
@synthesize image;

- (id)copyWithZone:(NSZone *)zone
{
    YTContact* copy = [[[self class] alloc] init];
    
    if (copy) {
        copy.first_name = [self.first_name copyWithZone:zone];
        copy.last_name = [self.last_name copyWithZone:zone];
        copy.value = [self.value copyWithZone:zone];
        copy.type = [self.type copyWithZone:zone];
        copy.phone_number = [self.phone_number copyWithZone:zone];
    }
    
    return copy;
}

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

@end
