//
//  YTLoginViewController.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YTViewController.h"


@interface YTLoginViewController : YTViewController

@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UIButton *gppButton;

@property (strong, nonatomic) UIView *bar;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *logoView;


- (IBAction)loginButtonWasPressed:(id)sender;
- (void) loginFailed;

@end
