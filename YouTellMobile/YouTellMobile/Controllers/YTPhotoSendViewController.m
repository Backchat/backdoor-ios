//
//  YTPhotoViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTPhotoSendViewController.h"

@interface YTPhotoSendViewController ()

@end

@implementation YTPhotoSendViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.sendButton.title = NSLocalizedString(@"Send", nil);
    self.cancelButton.title = NSLocalizedString(@"Cancel", nil);
    [self.toolbar setBackgroundImage:[UIImage imageNamed:@"navbar3.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

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
