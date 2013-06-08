//
//  YTLoginViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <GPPSignInButton.h>

#import "YTLoginViewController.h"
#import "YTFBHelper.h"
#import "YTGPPHelper.h"
#import "YTLoginButton.h"
#import "YTConfig.h"
#import "YTHelper.h"

@implementation YTLoginViewController

#pragma mark Custom methods

- (IBAction)loginButtonWasPressed:(id)sender
{
    [YTFBHelper openSession];
}

- (IBAction)gppButtonWasPressed:(id)sender
{
    [[YTGPPHelper sharedInstance] signIn];
}

- (void)loginFailed
{
    
}
/*

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown || ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}
- (NSInteger)supportedInterfaceOrientations
{
    NSInteger mask = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        mask |= UIInterfaceOrientationMaskLandscape;
    }
    return mask;
}
*/

/*
- (void)updateImage
{
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    NSString *name;
    CGPoint origin = self.view.frame.origin;
    
    if (w == 768 && h == 1004) {
        name = @"Default-Portrait~ipad";
    } else if (w == 1024 && h == 748) {
        name = @"Default-Landscape~ipad";
    } else if (w == 320 && h == 460) {
        name = @"Default";
    } else if (w == 320 && h == 548) {
        name = @"Default-568h";
    }
    
    if (origin.y != 0 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.imageView.frame = CGRectMake(0, -origin.y, w, h + origin.y);
    }
    
    self.imageView.image = [UIImage imageNamed:name];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [UIView transitionWithView:self.imageView duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [self updateImage];
    } completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateImage];
}
 */


- (void)viewDidLoad
{
    const CGFloat BUTTON_HEIGHT = 67;
    const CGFloat BUTTON_WIDTH = 270;
    
    CGRect frame;
    frame.size = self.view.frame.size;
    frame.origin = CGPointMake(0, 0);
    self.imageView = [[UIImageView alloc] initWithFrame:frame];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.image = [YTHelper imageNamed:@"signin2"];

    
    
    UIImage *logoImage = [YTHelper imageNamed:@"signin"];
    self.logoView = [[UIImageView alloc] initWithImage:logoImage];
    self.logoView.frame = CGRectMake((frame.size.width - logoImage.size.width) / 2, 40, logoImage.size.width, logoImage.size.height);
    self.logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
   
    UILabel *label = [[UILabel alloc]init];
    label.font = [UIFont systemFontOfSize:25];
    label.textColor = [UIColor whiteColor];
    label.text = NSLocalizedString(@"Backdoor", nil);
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    [label sizeToFit];
    CGRect labelFrame = label.frame;
    labelFrame.origin.y = self.logoView.frame.origin.y + self.logoView.frame.size.height - 10;
    labelFrame.origin.x = (frame.size.width - labelFrame.size.width) / 2;
    label.frame = labelFrame;
    
    self.gppButton = [[YTLoginButton alloc] initWithType:@"google"];
    self.gppButton.frame = CGRectMake((frame.size.width - BUTTON_WIDTH) / 2.0f, frame.size.height  - BUTTON_HEIGHT - 30, BUTTON_WIDTH, BUTTON_HEIGHT);
    [self.gppButton addTarget:self action:@selector(gppButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];

    self.button = [[YTLoginButton alloc] initWithType:@"facebook"];
    self.button.frame = CGRectMake((frame.size.width - BUTTON_WIDTH) / 2.0f, frame.size.height  - 2 * BUTTON_HEIGHT - 32, BUTTON_WIDTH, BUTTON_HEIGHT);
    [self.button addTarget:self action:@selector(loginButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.imageView];
    /*
    [self.view addSubview:self.logoView];
    [self.view addSubview:label];
     */

    if (CONFIG_FB_ENABLED) {
        [self.view addSubview:self.button];
    }
    
    /*
    self.gppButton = [[GPPSignInButton alloc] init];
    self.gppButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;


    CGRect gppFrame = self.gppButton.frame;
    gppFrame.size.width = 240;
    gppFrame.origin.x = (self.view.frame.size.width - gppFrame.size.width) / 2;
    gppFrame.origin.y = self.button.frame.origin.y - 60;
    self.gppButton.frame = gppFrame;
     */
    
    if (CONFIG_GPP_ENABLED) {
        [self.view addSubview:self.gppButton];
    }
}


@end
