//
//  YTTourViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTTourViewController.h"
#import "YTAppDelegate.h"
#import "YTFBHelper.h"
#import "YTGPPHelper.h"

#define PAGE_COUNT 3

@interface YTTourViewController ()

@end

@implementation YTTourViewController

+ (void)show
{
    [[YTAppDelegate current].currentMainViewController presentViewController:[[YTTourViewController alloc] init] animated:YES completion:nil];
}

- (void)loadPage:(NSInteger)page
{
    NSString *imageName;
    
    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width * page;
    BOOL isfb = [[YTAppDelegate current].userInfo[@"provider"] isEqualToString:@"facebook"];
    
    if (page == 0) {
        imageName = @"tour12";
    } else if (page == 1) {
        imageName = @"tour23";
    } else if (page == 2 && isfb) {
        imageName = @"tour32";
    } else {
        imageName = @"tour32_gpp";
    }
   
    NSString *lang = [NSLocale preferredLanguages][0];
    if ([lang isEqualToString:@"pt"] || [lang isEqualToString:@"pt-PT"]) {
        imageName = [imageName stringByAppendingString:@"_pt"];
    }
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = frame;
    imageView.image = [UIImage imageNamed:imageName];
    imageView.contentMode = UIViewContentModeTop;
    
    if (page == 2) {
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        CGRect frame;
        frame.size.width = 250;
        frame.origin.x = (imageView.frame.size.width - frame.size.width) / 2;
        frame.origin.y = 300;
        
        if (isfb) {
            [shareButton setBackgroundImage:[[UIImage imageNamed:@"fbsharebtn.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)] forState:UIControlStateNormal];
            [shareButton setTitle:NSLocalizedString(@"Share on Facebook", nil) forState:UIControlStateNormal];
            frame.size.height = 50;

        } else {
            [shareButton setBackgroundImage:[[UIImage imageNamed:@"tour_gpp_button"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 25, 25)] forState:UIControlStateNormal];
            [shareButton setTitle:NSLocalizedString(@"Share on Google+", nil) forState:UIControlStateNormal];
            frame.size.height = 67;
        }
        [shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        shareButton.titleLabel.font = [UIFont systemFontOfSize:17];
        shareButton.frame = frame;
        [shareButton addTarget:self action:@selector(shareButtonWasClicked) forControlEvents:UIControlEventTouchUpInside];


        
        [imageView addSubview:shareButton];
        
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelButton.titleLabel.textColor = [UIColor blackColor];
        cancelButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [cancelButton setTitle:NSLocalizedString(@"No, thanks", nil) forState:UIControlStateNormal];
        [cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [cancelButton sizeToFit];
        
        frame = cancelButton.frame;
        frame.origin.x = (imageView.frame.size.width - frame.size.width) / 2;
        frame.origin.y = 380;
        cancelButton.frame = frame;
        [cancelButton addTarget:self action:@selector(cancelButtonWasClicked) forControlEvents:UIControlEventTouchUpInside];
        
        [imageView addSubview:cancelButton];
        
        imageView.userInteractionEnabled = YES;
    }
    
    [self.scrollView addSubview:imageView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *background = [[UIImageView alloc] initWithFrame:self.view.bounds];
    background.image = [UIImage imageNamed:@"background2.png"];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    
    self.scrollView.pagingEnabled = YES;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * PAGE_COUNT, self.scrollView.frame.size.height);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
    for (int i=0;i<PAGE_COUNT;++i) {
        [self loadPage:i];
    }

    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = PAGE_COUNT;
    self.pageControl.currentPage = 0;
    self.pageControl.frame = CGRectMake(0, self.scrollView.frame.size.height - 25, self.scrollView.frame.size.width, 15);
    [self.pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:background];
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.pageControl];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.pageControlUsed) {
        return;
    }
    
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pageControlUsed = 0;
}

- (void)changePage:(id)sender {
    int page = self.pageControl.currentPage;
    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [self.scrollView scrollRectToVisible:frame animated:YES];
    self.pageControlUsed = 1;
}

- (void)cancelButtonWasClicked
{
    [[YTAppDelegate current].currentMainViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)shareButtonWasClicked
{
    [[YTAppDelegate current].currentMainViewController dismissViewControllerAnimated:YES completion:^{
        if ([[YTAppDelegate current].userInfo[@"provider"] isEqualToString:@"facebook"]) {
            [YTFBHelper presentFeedDialog];
        } else {
            [[YTGPPHelper sharedInstance] presentShareDialog];
        }
    }];
}

@end
