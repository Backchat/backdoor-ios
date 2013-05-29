//
//  YTWebViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTWebViewController.h"

#import "YTApiHelper.h"

@implementation YTWebViewController

#pragma mark Custom methods

- (id)initWithPage:(NSString *)page
{
    self = [super init];
    if (self) {
        self.page = page;
        self.title = @"";
    }
    return self;
}

- (id)initWithImage:(NSString *)secret
{
    self = [super init];
    if (self) {
        self.page = @"image";
        self.title = @"";
        self.secret = secret;
    }
    return self;
}

- (id)initWithUrl:(NSString *)url title:(NSString*)title
{
    self = [super init];
    if (self) {
        self.page = @"url";
        self.title = title;
        self.url = url;
    }
    return self;
}


#pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.page isEqualToString:@"image"]) {
        NSURL *baseUrl = [YTApiHelper baseUrl];
        NSString *html = [NSString stringWithFormat:@"<html><body><img src='%@images?secret=%@' /></body></html>", baseUrl, self.secret];
        NSLog(@"%@", html);
        [self.webView loadHTMLString:html baseURL:baseUrl];
    } else if ([self.page isEqualToString:@"url"]) {
        NSURL *myUrl = [NSURL URLWithString:self.url];
        [self.webView loadRequest:[NSURLRequest requestWithURL:myUrl]];
    } else {
        NSString *path = [[NSBundle mainBundle] pathForResource:self.page ofType:@"html"];
        NSURL *url = [NSURL fileURLWithPath:path];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }

    NSDictionary *titles = @{
        @"image": @"",
        @"url": self.title,
        @"privacy": NSLocalizedString(@"Privacy Policy", nil),
        @"terms": NSLocalizedString(@"Terms of Service", nil)
    };
    self.title = titles[self.page];
}

@end
