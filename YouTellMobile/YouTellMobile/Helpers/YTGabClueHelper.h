//
//  YTGabClueHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YTGabViewController;
@class YTSheetViewController;

@interface YTGabClueHelper : NSObject <UIActionSheetDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) YTGabViewController *gabView;
@property (strong, nonatomic) YTSheetViewController *sheet;
@property (strong, nonatomic) UIView *overlay;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIBarButtonItem *button;


- (id)initWithGabView:(YTGabViewController*)gabView;
- (void)setupClueButton;

- (void)requestClueButtonWasPressed:(id)sender;
- (void)buyCluesButtonWasPressed;

- (void)actionButtonWasPressed:(id)sender;


@end
