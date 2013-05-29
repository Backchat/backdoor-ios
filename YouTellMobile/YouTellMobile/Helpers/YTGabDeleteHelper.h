//
//  YTGabDeleteHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YTGabViewController;

@interface YTGabDeleteHelper : NSObject <UIAlertViewDelegate>

@property (weak, nonatomic) YTGabViewController *gabView;

- (id)initWithGabView:(YTGabViewController*)gabView;
- (void)setupDeleteButton;
- (void)deleteButtonWasPressed:(id)sender;

@end
