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
    
    self.alertView = [[UIAlertView alloc]
                      initWithTitle: nil // NSLocalizedString(@"Tag conversation", nil)
                      message: NSLocalizedString(@"Input name for anonymous user", nil)
                      delegate: self
                      cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                      otherButtonTitles: NSLocalizedString(@"Save", nil), nil
                      ];
    self.alertView.alertViewStyle = UIAlertViewStylePlainTextInput;

    return self;
}

- (UIBarButtonItem*)setupTagButton
{
    return [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Tag", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(tagButtonWasPressed:)];
}

# pragma mark Button handler methods

- (void)tagButtonWasPressed:(id)sender
{
    [self.alertView textFieldAtIndex:0].text = self.gabView.title;
    [self.alertView show];
}


# pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    NSString *tag = [alertView textFieldAtIndex:0].text;
    tag = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [self.gabView.gab tag:tag];
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    NSString *tag = [alertView textFieldAtIndex:0].text;
    tag = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return tag.length > 0;
}


@end