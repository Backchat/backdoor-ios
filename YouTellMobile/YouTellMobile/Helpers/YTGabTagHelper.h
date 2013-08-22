//
//  YTGabTagHelper.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YTGabViewController;

@interface YTGabTagHelper : NSObject <UIAlertViewDelegate>

@property (weak, nonatomic) YTGabViewController *gabView;
@property (strong, nonatomic) UIAlertView* alertView;

- (id)initWithGabView:(YTGabViewController*)gabView;
- (UIBarButtonItem*)setupTagButton;
- (void)tagButtonWasPressed:(id)sender;

@end
