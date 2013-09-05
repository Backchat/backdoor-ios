//
//  YTContact.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTContact.h"
#import "YTHelper.h"

@interface YTContact ()
{
    UIImage* _image;
}
@end

@implementation YTContact

@synthesize first_name;
@synthesize last_name;
@synthesize socialID;
@synthesize phone_number;
@synthesize type;

- (id)init
{
    if(self = [super init])
        _image = nil;
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    YTContact* copy = [[[self class] alloc] init];
    
    if (copy) {
        copy.first_name = [self.first_name copyWithZone:zone];
        copy.last_name = [self.last_name copyWithZone:zone];
        copy.socialID = [self.socialID copyWithZone:zone];
        copy.type = [self.type copyWithZone:zone];
        copy.phone_number = [self.phone_number copyWithZone:zone];
        copy->_image  = [_image copy];
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


- (UIImage*) image {
    if(_image)
        return _image;
    else
        return [YTHelper imageNamed:@"avatar6"];
}

- (void) setImage:(UIImage *)image
{
    _image = image;
}
@end
