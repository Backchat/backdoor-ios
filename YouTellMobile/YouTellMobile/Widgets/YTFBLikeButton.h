//
//  YTFBLikeButton.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YTFBLikeButton : UIWebView <UIWebViewDelegate>

@property (strong, nonatomic) NSURL *href;

- (void)load;

@end
