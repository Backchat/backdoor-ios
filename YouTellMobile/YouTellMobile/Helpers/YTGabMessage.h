//
//  YTGabMessage.h
//  Backdoor
//
//  Created by Lin Xu on 6/6/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTGabMessage : NSObject
@property (retain, nonatomic) NSString* content;
@property (assign, nonatomic) NSInteger kind;

- (id)initWithContent:(NSString*)content andKind:(NSInteger)kind;
+ (YTGabMessage*)messageWithContent:(NSString*)content andKind:(NSInteger)kind;
@end
