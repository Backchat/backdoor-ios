//
//  YTAbuseViewController.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "YTApiHelper.h"
#import "YTAbuseViewController.h"

@interface YTAbuseViewController ()

@end

@implementation YTAbuseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CGFloat y = 0;
    CGRect frame;
    
    self.title = NSLocalizedString(@"Report Abuse", nil);
    
    
    UILabel *label = [[UILabel alloc] init];
    label.text = NSLocalizedString(@"Please be as descriptive as possible\nand we will do our best\nto block the offender. Thank you.", nil);
    label.font = [UIFont boldSystemFontOfSize:14];
    label.textColor = [UIColor colorWithRed:0x24/255.0 green:0x6d/255.0 blue:0x00/255.0 alpha:1];
    label.numberOfLines = 3;
    label.textAlignment = NSTextAlignmentCenter;
    [label sizeToFit];
    frame = label.frame;
    frame.origin.y = (y += 20);
    frame.origin.x = (self.view.frame.size.width - frame.size.width) / 2;
    label.frame = frame;
    label.backgroundColor = [UIColor clearColor];

    y += 70;
    frame = CGRectMake(20, y, self.view.bounds.size.width - 40, self.view.bounds.size.height - self.navigationController.navigationBar.frame.size.height - y - 20);
    self.textView = [[UITextView alloc] init];
    self.textView.frame = frame;
    self.textView.returnKeyType = UIReturnKeySend;
    self.textView.layer.borderColor = [[UIColor grayColor] CGColor];
    self.textView.layer.borderWidth = 1;
    self.textView.layer.cornerRadius = 5;
    self.textView.layer.masksToBounds = YES;
    self.textView.delegate = self;
    
    [self.view addSubview:label];
    [self.view addSubview:self.textView];
    
    [self.textView becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

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


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (![text isEqualToString:@"\n"]) {
        return YES;
    }
    
    if ([self.textView.text isEqualToString:@""]) {
        return NO;
    }
    
    [YTApiHelper sendAbuseReport:self.textView.text success:^(id JSON) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Message delivered", nil) message:NSLocalizedString(@"Thank you for the report!", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        alert.delegate = self;
        [alert show];
    }];
    
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
