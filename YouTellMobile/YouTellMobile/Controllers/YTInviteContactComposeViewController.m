//
//  YTInviteContactComposeViewController.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTInviteContactComposeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "YTViewHelper.h"
#import "YTApiHelper.h"

@interface YTInviteContactComposeViewController ()
@property (nonatomic, retain) UITextView* textView;
@property (nonatomic, retain) UIButton* sendButton;
@property (nonatomic, retain) UILabel* phone;
@end

@implementation YTInviteContactComposeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIColor *color = [UIColor colorWithRed:0.859f green:0.886f blue:0.929f alpha:1.0f];
    [self.view setBackgroundColor:color];
    self.title = NSLocalizedString(@"Compose", nil);
    //cancel please
    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonWasClicked)];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(10,35,self.view.frame.size.width-20, 120)];
    [self.view addSubview:self.textView];
//    self.inputView.image = [[YTHelper imageNamed:@"inputview3"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    self.textView.layer.cornerRadius = 10;
    self.textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.textView.layer.borderWidth = 1;
    self.textView.font = [UIFont systemFontOfSize:16.0f];

    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10,10, 80, 17)];
    label.backgroundColor = [UIColor clearColor];
    label.text = @"To";
    [self.view addSubview:label];
    
    self.phone = [[UILabel alloc] initWithFrame:CGRectMake(50,10,200,17)];
    self.phone.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.phone];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.frame = CGRectMake(self.view.frame.size.width - 80.0f, 207, 69.0f, 30.0f);
    self.sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin);
    [self.sendButton addTarget:self action:@selector(sendPressed:) forControlEvents:UIControlEventTouchUpInside];

    UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 11.0f, 0.0f, 11.0f);
    UIImage *sendBack = [[UIImage imageNamed:@"sendbtn"] resizableImageWithCapInsets:insets];
    [self.sendButton setBackgroundImage:sendBack forState:UIControlStateNormal];
    [self.sendButton setBackgroundImage:sendBack forState:UIControlStateDisabled];
    
    NSString *title = NSLocalizedString(@"Send", nil);
    [self.sendButton setTitle:title forState:UIControlStateNormal];
    [self.sendButton setTitle:title forState:UIControlStateHighlighted];
    [self.sendButton setTitle:title forState:UIControlStateDisabled];
    self.sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.sendButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:0.5f] forState:UIControlStateDisabled];
    
    self.sendButton.enabled = YES;
    [self.view addSubview:self.sendButton];

}

- (void)cancelButtonWasClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)sendPressed:(UIButton*)sender
{
    [YTApiHelper sendInviteText:self.contact body:self.textView.text success:^(id JSON) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invite sent", nil)
                                                        message:NSLocalizedString(@"Your anonymous invite has been sent!", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [YTViewHelper showGabs]; //pop back to main screen
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.phone.text = self.contact.phone_number;
    self.textView.text = @"Someone you know wants you to try Backdoor! Anonymously message your friends. http://backdoor.com";
    [self.textView becomeFirstResponder];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
