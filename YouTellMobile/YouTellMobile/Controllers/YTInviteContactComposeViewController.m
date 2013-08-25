//
//  YTInviteContactComposeViewController.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <Mixpanel.h>

#import "YTInviteContactComposeViewController.h"
#import "YTViewHelper.h"
#import "YTApiHelper.h"
#import "YTHelper.h"
#import "YTMainViewHelper.h"

@interface YTInviteContactComposeViewController ()
@property (nonatomic, retain) UITextView* textView;
@property (nonatomic, retain) UIButton* sendButton;
@property (nonatomic, retain) UIView* contactView;
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
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];

    self.title = NSLocalizedString(@"Compose", nil);
    //cancel please
    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonWasClicked)];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(30,65,self.view.frame.size.width-60, 90)];
    [self.view addSubview:self.textView];
    self.textView.layer.cornerRadius = 10;
    self.textView.layer.borderColor = [[UIColor colorWithRed:170/255.0f green:170/255.0f blue:170/255.0f alpha:1.0] CGColor];
    self.textView.layer.borderWidth = 2;
    self.textView.font = [UIFont systemFontOfSize:16.0f];
    self.textView.textColor = [UIColor colorWithRed:111/255.0f green:111/255.0f blue:111/255.0f alpha:1.0];
       
    self.contactView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    self.contactView.backgroundColor = [UIColor whiteColor];
    
    UIView* subContactView = [[UIView alloc] initWithFrame:CGRectMake(60,0,self.view.frame.size.width-60,60)];
    [[YTMainViewHelper sharedInstance] addCellSubViewsToView:subContactView];
    [self.contactView addSubview:subContactView];
    [self.view addSubview:self.contactView];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(30,10, 80, 17)];
    label.backgroundColor = [UIColor clearColor];
    label.text = NSLocalizedString(@"To", nil);
    label.textColor = [UIColor colorWithRed:0.435 green:0.435 blue:0.435 alpha:1];
    [self.contactView addSubview:label];

    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.frame = CGRectMake(30,207,self.view.frame.size.width-60, 30);
    
    self.sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin);
    [self.sendButton addTarget:self action:@selector(sendPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self.sendButton setBackgroundImage:[YTHelper imageNamed:@"clue_button_inactive"] forState:UIControlStateNormal];
    [self.sendButton setBackgroundImage:[YTHelper imageNamed:@"clue_button_active"] forState:UIControlStateHighlighted];
    
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
    [[Mixpanel sharedInstance] track:@"Tapped Compose Invite View / Send Button"];

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
    [YTViewHelper showGabs:YES]; //pop back to main screen
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString* personalizedURL = @"http://bkdr.me";
    NSString* msgText = [NSString stringWithFormat:@"%@ %@",
                         NSLocalizedString(@"Someone you know wants you to try Backdoor! Anonymously message your friends.", nil),
                         personalizedURL];
    self.textView.text = msgText;
    [[YTMainViewHelper sharedInstance] setCellValuesInView:self.contactView
                                                     title:self.contact.name
                                                  subtitle:self.contact.phone_number
                                                      time:nil image:nil avatar:nil
                                          placeHolderImage:self.contact.image];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
