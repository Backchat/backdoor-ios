//
//  YTWebViewController.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTViewController.h"

@interface YTWebViewController : YTViewController

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSString *page;
@property (strong, nonatomic) NSString *secret;
@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) NSString *title;

- (id)initWithPage:(NSString*)page;
- (id)initWithImage:(NSString*)secret;
- (id)initWithUrl:(NSString*)url title:(NSString*)title;

@end
