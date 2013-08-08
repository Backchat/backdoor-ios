//
//  YTGabSendHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YTGabViewController;
@class YTContactWidget;

enum {
    YTMessageKindText,
    YTMessageKindPhoto
};

@interface YTGabSendHelper : NSObject <UITextFieldDelegate>

@property (weak, nonatomic) YTGabViewController *gabView;

@property (strong, nonatomic) UIPopoverController *popover;

- (id)initWithGabView:(YTGabViewController*)gabView;
- (void)updateButtons;
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text;
@end
