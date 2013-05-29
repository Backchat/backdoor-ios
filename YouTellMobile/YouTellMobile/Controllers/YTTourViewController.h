//
//  YTTourViewController.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTViewController.h"

@interface YTTourViewController : YTViewController <UIScrollViewDelegate>

@property (assign, nonatomic) NSInteger pageControlUsed;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIPageControl *pageControl;

+ (void)show;

@end
