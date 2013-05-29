//
//  YTPhotoViewController.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTViewController.h"

@class YTGabViewController;

@interface YTPhotoViewController : YTViewController

@property (strong, nonatomic) NSURL *url;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) YTGabViewController *gabView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

- (IBAction)doneButtonWasPressed:(id)sender;
- (id)initWithGabView:(YTGabViewController*)gabView url:(NSURL*)url;

@end
