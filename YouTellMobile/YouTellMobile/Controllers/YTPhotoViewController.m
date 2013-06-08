//
//  YTPhotoViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTPhotoViewController.h"
#import "YTGabViewController.h"

#import <SDWebImage/UIImageView+WebCache.h>

@interface YTPhotoViewController ()

@end

@implementation YTPhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)doneButtonWasPressed:(id)sender {
    [self.gabView dismissViewControllerAnimated:YES completion:nil];
}

- (id)initWithGabView:(YTGabViewController*)gabView url:(NSURL*)url
{
    self = [super init];
    if (self) {
        self.gabView = gabView;
        self.url = url;
        self.doneButton.title = NSLocalizedString(@"Done", nil);

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self.imageView setImageWithURL:self.url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [self.indicator stopAnimating];
    }];
    [self.toolbar setBackgroundImage:[UIImage imageNamed:@"navbar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    // Do any additional setup after loading the view from its nib.
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setToolbar:nil];
    [super viewDidUnload];
}
@end
