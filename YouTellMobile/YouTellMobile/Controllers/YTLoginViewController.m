//
//  YTLoginViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <GooglePlus/GPPSignInButton.h>
#import <Mixpanel.h>

#import "YTLoginViewController.h"
#import "YTFBHelper.h"
#import "YTGPPHelper.h"
#import "YTLoginButton.h"
#import "YTConfig.h"
#import "YTHelper.h"

@interface YTLoginViewController ()
{
    CGFloat button_height;
}
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UIButton *gppButton;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImageView *logoView;
@property (strong, nonatomic) UILabel* label;

- (void)loginButtonWasPressed:(id)sender;
- (void)gppButtonWasPressed:(id)sender;

- (void) updateLoginToMiddle;
- (void) updateLoginToTop;
@end

@implementation YTLoginViewController

#pragma mark Custom methods

- (void)loginButtonWasPressed:(id)sender
{
    [YTFBHelper requestAuth];
}

- (void)gppButtonWasPressed:(id)sender
{
    [[YTGPPHelper sharedInstance] requestAuth];
}

- (void) updateLoginToMiddle
{
    CGRect frame = self.view.frame;
    CGRect labelFrame = self.label.frame;
    
    int height_image = (frame.size.height - (self.logoView.image.size.height + labelFrame.size.height)) / 2;
    self.logoView.frame = CGRectMake((frame.size.width - self.logoView.image.size.width) / 2,
                                     height_image,
                                     self.logoView.image.size.width, self.logoView.image.size.height);
    labelFrame.origin.y = self.logoView.frame.origin.y + self.logoView.frame.size.height;
    labelFrame.origin.x = (frame.size.width - labelFrame.size.width) / 2;
    self.label.frame = labelFrame;
}

- (void) updateLoginToTop
{
    CGRect frame = self.view.frame;
    CGRect labelFrame = self.label.frame;
    
    CGFloat height_image_with_buttons = (frame.size.height -
                                         (self.logoView.image.size.height + self.label.frame.size.height +
                                          button_height)) / 2;
    
    self.logoView.frame = CGRectMake((frame.size.width - self.logoView.image.size.width) / 2,
                                     height_image_with_buttons,
                                     self.logoView.image.size.width, self.logoView.image.size.height);
    
    labelFrame.origin.y = self.logoView.frame.origin.y + self.logoView.frame.size.height;
    labelFrame.origin.x = (frame.size.width - labelFrame.size.width) / 2;
    self.label.frame = labelFrame;

}

- (void)viewDidLoad
{    
    CGRect frame;
    frame.size = self.view.frame.size;
    frame.origin = CGPointMake(0, 0);
    self.imageView = [[UIImageView alloc] initWithFrame:frame];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.image = [YTHelper imageNamed:@"background2"];    
    
    UIImage *logoImage = [YTHelper imageNamed:@"signin"];
    self.logoView = [[UIImageView alloc] initWithImage:logoImage];
    self.logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
       
    self.label = [[UILabel alloc]init];
    self.label.font = [UIFont systemFontOfSize:25];
    self.label.textColor = [UIColor whiteColor];
    self.label.text = NSLocalizedString(@"Backdoor", nil);
    self.label.backgroundColor = [UIColor clearColor];
    self.label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.label sizeToFit];
    
    [self updateLoginToMiddle];
        
    self.gppButton = [[YTLoginButton alloc] initWithType:@"google"];
    [self.gppButton addTarget:self action:@selector(gppButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];

    self.button = [[YTLoginButton alloc] initWithType:@"facebook"];
    [self.button addTarget:self action:@selector(loginButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];

    
    const CGFloat BUTTON_HEIGHT = 67;
    const CGFloat BUTTON_WIDTH = 270;
    const CGFloat BUTTON_GUTTER = 5;
    const CGFloat BUTTON_GUTTER_TOP = 12;
    
    button_height = BUTTON_GUTTER_TOP; //margin from bottom of backdoor label
    if(CONFIG_FB_ENABLED)
        button_height += BUTTON_HEIGHT;
    if(CONFIG_GPP_ENABLED)
        button_height += BUTTON_HEIGHT;
    
    if(CONFIG_FB_ENABLED && CONFIG_GPP_ENABLED)
        button_height += BUTTON_GUTTER; //margin between buttons
    
    //recalculate the height based ont he new button
    CGFloat height_image_with_buttons = (frame.size.height -
                                         (self.logoView.image.size.height + self.label.frame.size.height +
                                          button_height)) / 2;
    
    CGFloat button_top = height_image_with_buttons + self.logoView.image.size.height +
                            self.label.frame.size.height + BUTTON_GUTTER_TOP;
    
    if(CONFIG_GPP_ENABLED) {
        self.gppButton.frame = CGRectMake(
                                          (frame.size.width - BUTTON_WIDTH) / 2.0f,
                                          button_top, BUTTON_WIDTH, BUTTON_HEIGHT);
        
        if(CONFIG_FB_ENABLED) {
            self.button.frame = CGRectMake((frame.size.width - BUTTON_WIDTH) / 2.0f,
                                           button_top + BUTTON_HEIGHT + BUTTON_GUTTER,
                                           BUTTON_WIDTH, BUTTON_HEIGHT);
        }
    }
    else {
        if(CONFIG_FB_ENABLED) {//just FB..
            self.button.frame = CGRectMake(
                                           (frame.size.width - BUTTON_WIDTH) / 2.0f,
                                           button_top, BUTTON_WIDTH, BUTTON_HEIGHT);
            
        }
    }
    
    self.button.hidden = YES;
    self.gppButton.hidden = YES;
    
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.logoView];
    [self.view addSubview:self.label];

    [self.view addSubview:self.button];
    [self.view addSubview:self.gppButton];
}



const NSTimeInterval BUTTON_FADE_INTERVAL = 1.0;

- (void) showLoginButtons
{
    //do nothing if the buttons are already visible.
    if(!self.button.hidden || !self.gppButton.hidden)
        return;
    
    self.button.hidden = !CONFIG_FB_ENABLED;
    self.gppButton.hidden = !CONFIG_GPP_ENABLED;
    self.button.alpha = 0;
    self.gppButton.alpha = 0;
    
    [UIView animateWithDuration:BUTTON_FADE_INTERVAL animations:^{
        [self updateLoginToTop];
    }];
    [UIView animateWithDuration:BUTTON_FADE_INTERVAL delay:BUTTON_FADE_INTERVAL/2.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                            self.button.alpha = 1;
                            self.gppButton.alpha = 1;
                        }
                     completion:^(BOOL finished) {
                        }];
}

@end
