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
#import "YTAppDelegate.h"

@interface YTInviteContactComposeViewController ()
@property (nonatomic, retain) UITextView* textView;
@property (nonatomic, retain) UIButton* sendButton;
@property (nonatomic, retain) UIScrollView* contactView;
@property (nonatomic, retain) UIView* anonView;
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
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonWasClicked)];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(30,105,self.view.frame.size.width-60, 90)];
    [self.view addSubview:self.textView];
    self.textView.layer.cornerRadius = 10;
    self.textView.layer.borderColor = [[UIColor colorWithRed:170/255.0f green:170/255.0f blue:170/255.0f alpha:1.0] CGColor];
    self.textView.layer.borderWidth = 2;
    self.textView.font = [UIFont systemFontOfSize:16.0f];
    self.textView.textColor = [UIColor colorWithRed:111/255.0f green:111/255.0f blue:111/255.0f alpha:1.0];
    
    self.anonView = [[UIView alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, 36)];
    self.anonView.backgroundColor = [UIColor whiteColor];
    self.anonView.clipsToBounds = YES;
    UISwitch *sw = [[UISwitch alloc] init];
    sw.frame = CGRectMake(210, 3, 79, 27);
    sw.onImage = [YTHelper imageNamed:@"toggle-yes"];
    sw.offImage = [YTHelper imageNamed:@"toggle-no"];
    [sw addTarget:self action:@selector(toggleAnon:) forControlEvents:UIControlEventValueChanged];
    
    [self.anonView addSubview:sw];

    UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30,5,170,20)];
    textLabel.text = @"Send anonymously";
    textLabel.backgroundColor = [UIColor clearColor];
    [self.anonView addSubview:textLabel];

    [self.view addSubview:self.anonView];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.frame = CGRectMake(30,247,self.view.frame.size.width-60, 30);
    
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

    UIView* contactBack = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, 60)];
    contactBack.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:contactBack];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(30,10, 80, 17)];
    label.backgroundColor = [UIColor clearColor];
    label.text = NSLocalizedString(@"To", nil);
    label.textColor = [UIColor colorWithRed:0.435 green:0.435 blue:0.435 alpha:1];
    [self.view addSubview:label];
    
    self.contactView = [[UIScrollView alloc] initWithFrame:CGRectMake(65, 0, self.view.frame.size.width, 60)];
    self.contactView.scrollEnabled = YES;
    self.contactView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.contactView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)buildText:(BOOL)anon
{
    NSString* personalizedURL = @"http://bkdr.me";
    NSString* msg = nil;
    if(anon)
        msg = NSLocalizedString(@"Someone you know wants you to try Backdoor! Anonymously message your friends.", nil);
    else
        msg = NSLocalizedString(@"Your friend %@ wants you to try Backdoor! Anonymously message your friends.", nil);
    
    NSString* msgText = [NSString stringWithFormat:@"%@ %@",
                         [NSString stringWithFormat:msg, YTAppDelegate.current.currentUser.name],
                         personalizedURL];
    
    self.textView.text = msgText;
}

- (void)toggleAnon:(UISwitch*)sw
{
    [self buildText:[sw isOn]];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)keyboardWillChange:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        if([notification name] == UIKeyboardWillShowNotification) {
            self.anonView.frame = CGRectMake(0, 60, self.view.frame.size.width, 0);
            self.textView.frame = CGRectMake(30,65,self.view.frame.size.width-60, 90);
            self.sendButton.frame = CGRectMake(30,160,self.view.frame.size.width-60, 30);

        }
        else {
            self.anonView.frame = CGRectMake(0, 60, self.view.frame.size.width, 36);
            self.textView.frame = CGRectMake(30,100,self.view.frame.size.width-60, 90);
            self.sendButton.frame = CGRectMake(30,247,self.view.frame.size.width-60, 30);

        }
    }];
}

- (void)cancelButtonWasClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)sendPressed:(UIButton*)sender
{
    [[Mixpanel sharedInstance] track:@"Tapped Compose Invite View / Send Button"];

    [YTApiHelper sendInviteText:self.contacts body:self.textView.text success:^(id JSON) {
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
    [self buildText:NO];
    
    [[self.contactView subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];    
    
    if(self.contacts.count == 1) {
        UIView* subContactView = [[UIView alloc] initWithFrame:CGRectMake(-20,0,self.view.frame.size.width-60,60)];
        YTContact* contact = self.contacts[0];
        [[YTMainViewHelper sharedInstance] addCellSubViewsToView:subContactView];
         [[YTMainViewHelper sharedInstance] setCellValuesInView:subContactView
                                                          title:contact.name
                                                       subtitle:contact.phone_number
                                                           time:nil image:nil avatar:nil
                                               placeHolderImage:contact.image];

        [self.contactView addSubview:subContactView];
        self.contactView.scrollEnabled = NO;
    }
    else {
        int i=0;
        int offset = 60;
        
        for(YTContact* c in self.contacts) {
            UIImageView* imageView = [[UIImageView alloc] initWithImage:c.image];
            imageView.frame = CGRectMake(i * offset, 5, 50, 50);
            [self.contactView addSubview:imageView];
            self.contactView.scrollEnabled = YES;
            i++;
        }
        
        self.contactView.contentSize = CGSizeMake(i * offset + 70, 60);
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
