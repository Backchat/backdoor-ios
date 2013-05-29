//
//  YTFeedbackViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "YTApiHelper.h"
#import "YTAppDelegate.h"
#import "YTFeedbackViewController.h"

@implementation YTFeedbackViewController

# pragma mark Custom methods

- (void)keyboardWillChange:(NSNotification*)notification
{
    int factor = ([notification name] == UIKeyboardWillShowNotification) ? -1 : 1;
    NSDictionary *userInfo = [notification userInfo];
    CGRect kbFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:self.view.window];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = self.textView.frame;
        frame.size.height += kbFrame.size.height * factor;
        self.textView.frame = frame;
    }];
}

# pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textView.layer.borderColor = [[UIColor grayColor] CGColor];
    self.textView.layer.borderWidth = 1;
    self.textView.layer.masksToBounds = YES;
    
    self.title = NSLocalizedString(@"Feedback", nil);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

# pragma mark UITextViewDelegate methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (![text isEqualToString:@"\n"]) {
        return YES;
    }
    
    if ([self.textView.text isEqualToString:@""]) {
        return NO;
    }
    
    NSNumber *rating = [NSNumber numberWithInteger:self.ratingControl.selectedSegmentIndex + 1];
   
    [YTApiHelper sendFeedback:self.textView.text rating:rating success:^(id JSON) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Message delivered", nil) message:NSLocalizedString(@"Thank you for your feedback!", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
    }];

    return NO;
}

# pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    self.ratingControl.selectedSegmentIndex = UISegmentedControlNoSegment;
    self.textView.text = @"";
    [self.textView resignFirstResponder];
    if (!delegate.usesSplitView) {
        [delegate.navController popViewControllerAnimated:YES];
    }
}

@end
