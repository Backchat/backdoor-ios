//
//  YTSheetViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTSheetViewController.h"

@interface YTSheetViewController ()

@end

@implementation YTSheetViewController

- (id)init
{
    id ret = [super init];
    if (!ret) {
        return ret;
    }

    self.sheetView = [[UIView alloc] init];
    self.overlay = [[UIView alloc] init];
    
    return ret;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.sheetView];
    [self.view setBackgroundColor:[UIColor clearColor]];
}

- (void)presentFromView:(UIView *)view
{
    self.overlay.backgroundColor = [UIColor blackColor];
    self.overlay.alpha = 0;
    self.overlay.frame = CGRectMake(0,20,view.frame.size.width,view.frame.size.height-20);
    
    [view addSubview:self.overlay];
    
    [view addSubview:self.view];
    
    CGRect frame;
    
    frame = self.view.frame;
    frame.size = view.frame.size;
    frame.origin = CGPointMake(0, 0);
    self.view.frame = frame;
    
    frame = self.sheetView.frame;
    frame.origin.x = 0;
    frame.origin.y = self.view.bounds.size.height;
    frame.size.width = self.view.frame.size.width;
    self.sheetView.frame = frame;
    
    [UIView animateWithDuration:0.5 animations:^{
        CGRect frame = self.sheetView.frame;
        frame.origin.x = 0;
        frame.origin.y = self.view.bounds.size.height - self.sheetView.frame.size.height;
        self.sheetView.frame = frame;
        self.overlay.alpha = 0.85;
    }];   
}

- (void)dismiss
{
    [UIView animateWithDuration: 0.5 animations:^{
        CGRect frame = self.sheetView.frame;
        frame.origin.y = self.view.bounds.size.height;
        self.sheetView.frame = frame;
        self.overlay.alpha = 0;
    } completion:^(BOOL finished) {
        [self.overlay removeFromSuperview];
        [self.view removeFromSuperview];
    }];
}

@end
