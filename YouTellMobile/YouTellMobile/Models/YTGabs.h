//
//  YTGabs.h
//  Backdoor
//
//  Created by Lin Xu on 8/19/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTGab.h"

@interface YTGabs : NSObject

- (id) initWithSearchString:(NSString*)search;
- (id) init;
- (YTGab*) gabAtIndex:(int)index;
- (int)indexForGab:(YTGab*)gab;

+ (int) totalGabCount;
+ (void) deleteGab:(YTGab*)gab;

@property (assign, readonly) int count;

+ (void)updateGabs;

@end
extern NSString* const YTGabsUpdatedNotification;