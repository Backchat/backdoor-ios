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

- (id)initWithGabView:(YTGabViewController*)gabView;
- (void)setupTagButton:(BOOL)visible;
- (void)tagButtonWasPressed:(id)sender;

@end
