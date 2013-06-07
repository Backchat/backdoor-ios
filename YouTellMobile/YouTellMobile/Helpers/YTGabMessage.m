//
//  YTGabMessage.m
//  Backdoor
//
//  Created by Lin Xu on 6/6/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTGabMessage.h"

@implementation YTGabMessage
- (id)initWithContent:(NSString*)content andKind:(NSInteger)kind
{
    if(self = [super init]) {
        self.content = content;
        self.kind = kind;
    }
    return self;
}
+ (YTGabMessage*)messageWithContent:(NSString*)content andKind:(NSInteger)kind
{
    return [[YTGabMessage alloc] initWithContent:content andKind:kind];
}

@end