//
//  YTFeedbackViewController.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTViewController.h"

@interface YTFeedbackViewController : YTViewController <UITextViewDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ratingControl;

- (void)keyboardWillChange:(NSNotification*)notification;

@end
