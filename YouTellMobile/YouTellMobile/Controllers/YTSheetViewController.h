//
//  YTClueViewController.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTViewController.h"

@interface YTSheetViewController : YTViewController

@property (strong, nonatomic) UIView *sheetView;
@property (strong, nonatomic) UIView *overlay;

- (void)dismiss;
- (void)present;
@end
