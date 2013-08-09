//
//  YTGabSendHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <NSString+JSMessagesView.h>
#import <Mixpanel.h>
#import <Facebook-iOS-SDK/FacebookSDK/FacebookSDK.h>

#import "YTGabSendHelper.h"
#import "YTGabViewController.h"
#import "YTApiHelper.h"
#import "YTAppDelegate.h"
#import "YTViewHelper.h"
#import "YTHelper.h"
#import "YTModelHelper.h"
#import "YTFBHelper.h"
#import "YTAppDelegate.h"

@implementation YTGabSendHelper

- (id)initWithGabView:(YTGabViewController*)gabView
{
    self = [super init];
    if (!self) {
        return self;
    }
    
    self.gabView = gabView;
    
    [self updateButtons];
    
    return self;
}

# pragma mark UITextViewDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    static NSCharacterSet *digitSet = nil;
    
    if (!digitSet) {
        digitSet = [NSCharacterSet decimalDigitCharacterSet];
    }
    
    if (string.length == 0) {
        return YES;
    }
    
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:newString];
    
    return [digitSet isSupersetOfSet:set];
}

- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    [self.gabView.inputView.textView setText:nil];
    [self.gabView textViewDidChange:self.gabView.inputView.textView];
    [self.gabView queueMessage:text ofKind:YTMessageKindText];
}


- (void)updateButtons
{
    self.gabView.inputView.sendButton.enabled = ([self.gabView.inputView.textView.text trimWhitespace].length > 0);
    self.gabView.inputView.cameraButton.enabled = true;
}

@end
