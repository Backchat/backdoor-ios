//
//  YTRateHelper.h
//  Backdoor
//
//  Created by Łukasz S on 7/26/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTViewHelper.h"

#import <iRate.h>

@interface YTRateHelper : YTViewHelper <iRateDelegate>

+ (YTRateHelper*)sharedInstance;
- (void)setup;
- (void)run;
- (void)reset;
@end
