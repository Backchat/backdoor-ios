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
#import "YTContactWidget.h"
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
    
    CGRect contactWidgetFrame = CGRectMake(0, 0, self.gabView.view.bounds.size.width, 44);
    CGRect contactTableFrame = CGRectMake(0, 44, self.gabView.view.bounds.size.width, self.gabView.view.frame.size.height - contactWidgetFrame.size.height - self.gabView.inputView.frame.size.height);
    
    self.contactTable = [[UITableView alloc] initWithFrame:contactTableFrame style:UITableViewStylePlain];
    self.contactTable.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contactTable.backgroundColor = [UIColor clearColor];
    
    self.contactWidget = [[YTContactWidget alloc] initWithFrame:contactWidgetFrame tableView:self.contactTable];
    self.contactWidget.delegate = self;
    self.contactWidget.hidden = self.gabView.gab != nil;
    self.contactWidget.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self.gabView.view addSubview:self.contactTable];
    [self.gabView.view addSubview:self.contactWidget];
    
    [self updateButtons];

    
    return self;
}

# pragma mark YTContactsViewDelegate methods

- (void)changedSelectedContact:(NSDictionary *)contact
{
    [[Mixpanel sharedInstance] track:@"Selected Thread Receiver"];
    [self updateButtons];
}

- (void)showContactViewController:(YTContactsViewController*)contactViewController
{
    if ([YTAppDelegate current].usesSplitView) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:contactViewController];
        [self.popover presentPopoverFromRect:self.contactWidget.frame inView:self.gabView.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.gabView.navigationController pushViewController:contactViewController animated:YES];
    }
}

- (void)hideContactViewController
{
    if ([YTAppDelegate current].usesSplitView) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self.gabView.navigationController popViewControllerAnimated:YES];
    }
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
    self.gabView.inputView.sendButton.enabled = (([self.gabView.inputView.textView.text trimWhitespace].length > 0) && [self selectedContact]);
    
    self.gabView.inputView.cameraButton.enabled = [self selectedContact];
}

- (void)keyboardWillShowHide:(NSNotification *)notification
{
    int factor = ([notification name] == UIKeyboardWillShowNotification) ? -1 : 1;
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect kbFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbFrame = [self.gabView.view convertRect:kbFrame fromView:self.gabView.view.window];
    CGRect oldRect = self.contactTable.frame;
    CGRect newRect = CGRectMake(oldRect.origin.x, oldRect.origin.y, oldRect.size.width, (oldRect.size.height + (kbFrame.size.height * factor)));
    self.contactTable.frame = newRect;
}

- (BOOL)selectedContact
{
    if (self.gabView.gab) {
        return YES;
    }
    
    if (self.contactWidget.selectedContact) {
        return YES;
    }
    
    return NO;
}

@end
