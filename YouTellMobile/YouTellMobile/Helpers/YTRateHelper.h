//
//  YTRateHelper.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTViewHelper.h"

#import <iRate.h>

@interface YTRateHelper : YTViewHelper <iRateDelegate>

+ (YTRateHelper*)sharedInstance;
- (void)setup;
- (void)run;

@end
