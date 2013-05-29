//
//  YTTwitterHelper.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTTwitterHelper : NSObject

@property (weak, nonatomic) UIViewController *parentController;

+ (YTTwitterHelper*)sharedInstance;
- (void)showTweetSheet:(UIViewController*)controller;

@end
