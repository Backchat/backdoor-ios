//
//  YTGabViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.

#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>

#import <Base64/MF_Base64Additions.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <Flurry.h>
#import <Mixpanel.h>

#import "YTGabViewController.h"
#import "YTApiHelper.h"
#import "YTAppDelegate.h"
#import "YTModelHelper.h"
#import "YTViewHelper.h"
#import "YTWebViewController.h"
#import "YTPhotoViewController.h"
#import "YTHelper.h"
#import "YTFBHelper.h"
#import "YTGabMessage.h"
#import "YTNewGabViewController.h"
#import "YTGPPHelper.h"

@interface YTGabViewController ()
@property (nonatomic, retain) YTFriend* friend;
@property (strong, nonatomic) UIActivityIndicatorView* backgroundSpinner;
@property (strong, nonatomic) UIActivityIndicatorView* rowSpinner;

@property (strong, nonatomic) YTGabPhotoHelper *photoHelper;
@property (strong, nonatomic) YTGabTagHelper *tagHelper;
@property (weak, nonatomic) UIActivityIndicatorView* spinner;
@property (strong, nonatomic) UIView* footerView;
@end

@implementation YTGabViewController

- (void) setGab:(YTGab*) gab
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YTGabUpdated object:gab];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YTGabMessageUpdated object:gab];
    
    self->_gab = gab;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gabUpdated:)
                                                 name:YTGabUpdated
                                               object:gab];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gabMessagesUpdated:)
                                                 name:YTGabMessageUpdated
                                               object:gab];
    
}

- (id) initWithGab:(YTGab*) gab
{
    if(self = [self initWithNibName:nil bundle:nil]) {
        self.gab = gab;
    }
    return self;
}

- (id) initWithFriend:(YTFriend*)f
{
    if(self = [self initWithNibName:nil bundle:nil]) {
        self.friend = f;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.photoHelper = [[YTGabPhotoHelper alloc] initWithGabView:self];
        self.clueHelper = [[YTGabClueHelper alloc] initWithGabView:self];
        self.tagHelper = [[YTGabTagHelper alloc] initWithGabView:self];
    }
    return self;
}

# pragma mark Interface initialization methods
- (void)setupView
{
    if(!self.friend) {
        if([self.gab isFakeGab] || self.gab.total_count.integerValue > 0) {
            //this means we have at least the minimium data to create the toolbar;
            self.title = self.gab.gabTitle;

            if (!self.gab.sent.boolValue) {
                self.navigationItem.rightBarButtonItems = @[[self.clueHelper setupClueButton],[self.tagHelper setupTagButton]];
                
                [self.inputToolBarView.sendButton setBackgroundImage:[[YTHelper imageNamed:@"sendbtn_blue_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]
                                                            forState:UIControlStateNormal];
                [self.inputToolBarView.sendButton setBackgroundImage:[[YTHelper imageNamed:@"sendbtn_blue_inactive"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]
                                                            forState:UIControlStateDisabled];
   
            }
            else {
                self.navigationItem.rightBarButtonItems = nil;
                
                [self.inputToolBarView.sendButton setBackgroundImage:[[YTHelper imageNamed:@"sendbtn"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]
                                                            forState:UIControlStateNormal];
                [self.inputToolBarView.sendButton setBackgroundImage:[[YTHelper imageNamed:@"sendbtn"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]
                                                            forState:UIControlStateDisabled];
                
                UIColor *titleShadow = [UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:1.0f];
                [self.inputToolBarView.sendButton setTitleShadowColor:titleShadow forState:UIControlStateNormal];
                [self.inputToolBarView.sendButton setTitleShadowColor:titleShadow forState:UIControlStateHighlighted];
                self.inputToolBarView.sendButton.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
            }
        }
        /*TODO SPLIT if ([YTAppDelegate current].usesSplitView) {
         [YTAppDelegate current].currentMainViewController.selectedGabId = [self.gab valueForKey:@"id"];
         }*/
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Messages", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];

        self.navigationItem.hidesBackButton = NO;
    }
    else {
        self.title = self.friend.name;
        
        /* TODO SPLIT if (![[YTAppDelegate current] usesSplitView]) */
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
        self.navigationItem.hidesBackButton = YES;
    }
}

- (void)dismiss
{
    [[Mixpanel sharedInstance] track:@"Cancelled Thread Compose"];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)postNewMessage:(NSString*)content ofKind:(int)kind
{
    if(self.gab) {
        [self.gab postNewMessage:content ofKind:kind];
    }
    else {
        self.gab = [YTGab createGabWithFriend:self.friend
                                   andMessage:content ofKind:kind];
        //remove the friend object.
        self.friend = nil;
        //we should now remove the cancel button, and also 
        
        [self setupView];
        [self.tableView reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.gab messageCount];
}

- (UIButton *)leftAccessoryButton
{
    return self.photoHelper.cameraButton;
}

- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    [self postNewMessage:text ofKind:YTMessageKindText];
    [self finishSend];
}

- (void)messageTappedAtIndexPath:(NSIndexPath*)indexPath
{
    YTGabMessage* message = [self.gab messageAtIndex:indexPath.row];
    if(message.status.integerValue == YTGabMessageStatusFailed)
    {
        [message repostMessage];
    }
    else if(message.kind.integerValue == YTMessageKindPhoto) {
        NSString *secret = message.secret;
        NSURL *baseUrl = [YTApiHelper baseUrl];
        NSString *urlString = [NSString stringWithFormat:@"%@images?secret=%@", baseUrl, secret];
        NSURL *url = [NSURL URLWithString:urlString];
        
        YTPhotoViewController *photoView = [[YTPhotoViewController alloc] initWithGabView:self url:url];
        [self presentViewController:photoView animated:YES completion:nil];
    }
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YTGabMessage* message = [self.gab messageAtIndex:indexPath.row];
    BOOL messageSent = message.sent.boolValue;

    return messageSent ? JSBubbleMessageTypeOutgoing : JSBubbleMessageTypeIncoming;
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    return JSMessagesViewTimestampPolicyCustom;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    return JSMessagesViewAvatarPolicyNone;
}

- (JSAvatarStyle)avatarStyle
{
    return JSAvatarStyleNone;
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return JSBubbleMessageStyleCustom;
}

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YTGabMessage* message = [self.gab messageAtIndex:indexPath.row];

    return message.content;
}

- (UIView *)viewForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YTGabMessage* message = [self.gab messageAtIndex:indexPath.row];
    if(message.kind.integerValue == YTMessageKindPhoto)
    {
        UIImageView* view = [[UIImageView alloc] initWithImage:message.image];
        view.contentMode = UIViewContentModeScaleAspectFill;
        view.frame = CGRectMake(0,0, 190, 190);
        return view;
    }
    else
        return nil;
}

    
- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YTGabMessage* message = [self.gab messageAtIndex:indexPath.row];
    NSDate *localDate = [YTHelper localDateFromUtcDate:message.created_at];

    return localDate;
}

- (BOOL)hasSubtitleForRowAtIndexPath:(NSIndexPath*)indexPath {
    YTGabMessage* message = [self.gab messageAtIndex:indexPath.row];

    NSInteger status = message.status.integerValue;
    return  status == YTGabMessageStatusFailed || status == YTGabMessageStatusDelivering;
}

- (NSString*)subtitleForRowAtIndexPath:(NSIndexPath*)indexPath {
    YTGabMessage* message = [self.gab messageAtIndex:indexPath.row];
    
    NSInteger status = message.status.integerValue;
    if(status == YTGabMessageStatusDelivering)
        return NSLocalizedString(@"Delivering", nil);
    else
        return NSLocalizedString(@"Failed. Tap to resend", nil);
}

- (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0)
        return true;
    else {
        //get the one before
        YTGabMessage* before = [self.gab messageAtIndex:indexPath.row-1];
        YTGabMessage* thisOne = [self.gab messageAtIndex:indexPath.row];
        NSTimeInterval diff = [thisOne.created_at timeIntervalSinceDate:before.created_at];
        if(diff < 120) //2 minutes
            return false;
        else
            return true;
    }
}

- (UIImage*)bubbleImageForIncomingMessageAtIndexPath:(NSIndexPath *)path withSelection:(BOOL)selected
{
    bool sendingToAnonymous = self.gab.sent.boolValue;
    UIImage* image;
    if(sendingToAnonymous)
        image = [YTHelper imageNamed:@"bubble_someone_2_2"];
    else
        image = [YTHelper imageNamed:@"bubble_someone_2_1"];
    
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(15,15,17,15)];
}

- (UIImage*)bubbleImageForOutgoingMessageAtIndexPath:(NSIndexPath *)path withSelection:(BOOL)selected
{
    bool sendingToAnonymous = self.gab.sent.boolValue;
    UIImage* image = nil;
    if(sendingToAnonymous)
        image = [YTHelper imageNamed:@"bubble_me_2_2"];
    else
        image = [YTHelper imageNamed:@"bubble_me_2_1"];
    
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(15,15,17,15)];

}

- (UIColor*)textColorForMessageAtIndexPath:(NSIndexPath *)path
{
    return [UIColor whiteColor];
}

# pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setBackgroundColor:[UIColor colorWithRed:0xed/255.0 green:0xec/255.0 blue:0xec/255.0 alpha:1]];
 
    self.delegate = self;
    self.dataSource = self;
    
    self.backgroundSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.backgroundSpinner setColor:[UIColor grayColor]];
    
    self.rowSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.rowSpinner setColor:[UIColor grayColor]];

    self.tableView.backgroundView = [UIView new];
    [self repositionBackgroundSpinner];
    [self.view addSubview:self.backgroundSpinner];

    int spinnerSize = self.rowSpinner.bounds.size.height;
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, spinnerSize + 7)];
    self.rowSpinner.frame = CGRectMake((self.view.frame.size.width - spinnerSize)/2.0,
                                    0, spinnerSize, spinnerSize);
    [self.footerView addSubview:self.rowSpinner];
    
    self.navigationItem.rightBarButtonItems = nil;
    self.title = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appActivated:) name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    self.inputToolBarView.textView.keyboardDelegate = self;
    
    [self setupView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)appActivated:(NSNotification*)note
{
    if(self.view.window && !self.friend)
        [self.gab update:YES];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(self.gab) {
        [self showSpinner];
        
        [self.gab update:YES];
        
        if(self.gab.messageCount != 0) {
            [self.tableView reloadData];
            [self scrollToFooter];
        }
        
        [self.gab clearUnread];
    }
    else {
        [self.inputToolBarView.textView becomeFirstResponder];
    }

}

- (void) showSpinner
{
    if(self.gab.messageCount != 0)
    {
        self.spinner = self.rowSpinner;
    }
    else {
        self.spinner = self.backgroundSpinner;
    }

    if(self.spinner == self.rowSpinner) {
        //we have to show the row spinny
        self.tableView.tableFooterView = self.footerView;
    }
    
    [self.spinner startAnimating];
}

- (void) stopSpinner
{
    [self.spinner stopAnimating];

    if(self.spinner == self.rowSpinner) {
        self.tableView.tableFooterView = nil;
    }
}

- (void) scrollToFooter
{
    CGPoint newContentOffset = CGPointMake(0, MAX(0,[self.tableView contentSize].height - self.tableView.bounds.size.height));
    
    [self.tableView setContentOffset:newContentOffset animated:YES];
}

//overide for background spinner
- (void)keyboardWillShowHide:(NSNotification *)notification
{
    [super keyboardWillShowHide:notification];
    /* copied from parent so we can animate the background spinner as needed*/
    /* also, don't animate anything if we are showing the tag helper */
    if(self.tagHelper.alertView.visible)
        return;
    
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self repositionBackgroundSpinner];
                     }
                     completion:^(BOOL finished) {
                     }];
}

//overide for background spinner
- (void)repositionBackgroundSpinner
{
    CGRect inputViewFrame = self.inputToolBarView.frame;
    self.backgroundSpinner.center = CGPointMake(self.tableView.backgroundView.frame.size.width/2,
                                                inputViewFrame.origin.y/2);
}

//TODO c&p from JSMessagesViewController.m
- (void)keyboardDidScrollToPoint:(CGPoint)pt
{
    CGRect inputViewFrame = self.inputToolBarView.frame;
    CGPoint keyboardOrigin = [self.view convertPoint:pt fromView:nil];
    inputViewFrame.origin.y = keyboardOrigin.y - inputViewFrame.size.height;
    self.inputToolBarView.frame = inputViewFrame;
    [self repositionBackgroundSpinner];
}

- (void)keyboardWillBeDismissed
{
    CGRect inputViewFrame = self.inputToolBarView.frame;
    inputViewFrame.origin.y = self.view.bounds.size.height - inputViewFrame.size.height;
    self.inputToolBarView.frame = inputViewFrame;
    [self repositionBackgroundSpinner];
}

- (void)keyboardWillSnapBackToPoint:(CGPoint)pt
{
    CGRect inputViewFrame = self.inputToolBarView.frame;
    CGPoint keyboardOrigin = [self.view convertPoint:pt fromView:nil];
    inputViewFrame.origin.y = keyboardOrigin.y - inputViewFrame.size.height;
    [self repositionBackgroundSpinner];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //TODO remove currentgabviewcontroller
    [YTAppDelegate current].currentGabViewController = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [YTAppDelegate current].currentGabViewController = self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return NO;
}

- (void)gabUpdated:(NSNotification*) note
{
    NSLog(@"gab updated");
    [self setupView];
    [self.tableView reloadData];
    [self stopSpinner];
    [self scrollToBottomAnimated:YES];
}

- (void)gabMessagesUpdated:(NSNotification*)note
{
    NSLog(@"gab messages updated");

    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

@end
