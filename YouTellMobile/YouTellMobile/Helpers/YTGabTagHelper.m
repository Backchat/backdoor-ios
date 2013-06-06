//
//  YTGabTagHelper.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTGabTagHelper.h"
#import "YTApiHelper.h"
#import "YTViewHelper.h"
#import "YTGabViewController.h"

@implementation YTGabTagHelper

- (id)initWithGabView:(YTGabViewController*)gabView
{
    self = [super init];
    if (!self) {
        return self;
    }
    self.gabView = gabView;
    
    return self;
}

- (void)setupTagButton:(BOOL)visible
{
    NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.gabView.navigationItem.rightBarButtonItems];
    
    if (visible && buttons.count > 1) {
        return;
    }
    
    if (!visible && buttons.count <= 1) {
        return;
    }
    
    if (!visible) {
        [buttons removeObjectAtIndex:1];
    } else {
        UIBarButtonItem *tagBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Tag", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(tagButtonWasPressed:)];
    
        [buttons insertObject:tagBarButtonItem atIndex:1];
    }
    self.gabView.navigationItem.rightBarButtonItems = buttons;
}

# pragma mark Button handler methods

- (void)tagButtonWasPressed:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: nil // NSLocalizedString(@"Tag conversation", nil)
                          message: NSLocalizedString(@"Input name for anonymous user", nil)
                          delegate: self
                          cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                          otherButtonTitles: NSLocalizedString(@"Save", nil), nil
                          ];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].text = self.gabView.title;
    [alert show];
}


# pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    NSString *tag = [alertView textFieldAtIndex:0].text;
    tag = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [YTApiHelper tagGab:[self.gabView.gab valueForKey:@"id"] tag:tag success:^(id JSON) {
        [YTViewHelper refreshViews];
    }];
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    NSString *tag = [alertView textFieldAtIndex:0].text;
    tag = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return tag.length > 0;
}


@end