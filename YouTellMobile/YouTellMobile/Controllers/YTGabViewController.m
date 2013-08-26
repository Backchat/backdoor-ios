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

#import "JSMessagesViewController.h"
#import "JSMessageInputView.h"
#import "NSString+JSMessagesView.h"

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
    if(self = [super initWithNibName:nil bundle:nil]) {
        self.gab = gab;
    }
    return self;
}

- (id) initWithFriend:(YTFriend*)f
{
    if(self = [super initWithNibName:nil bundle:nil]) {
        self.friend = f;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
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
                [self.inputView.sendButton setBackgroundImage:[[YTHelper imageNamed:@"sendbtn_blue_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]                                    forState:UIControlStateNormal];
                [self.inputView.sendButton setBackgroundImage:[[YTHelper imageNamed:@"sendbtn_blue_inactive"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]                                    forState:UIControlStateDisabled];
            }
            else {
                self.navigationItem.rightBarButtonItems = nil;
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

- (void)updateSendButton
{
    self.inputView.sendButton.enabled = ([self.inputView.textView.text trimWhitespace].length > 0);
    self.inputView.cameraButton.enabled = true;
}

- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    [self.inputView.textView setText:nil];
    [self textViewDidChange:self.inputView.textView];
    
    [self postNewMessage:text ofKind:YTMessageKindText];
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

#pragma mark UIBubbleTableViewDataSource

- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    if(self.gab)
        return self.gab.messageCount;
    else
        return 0;
}

- (NSBubbleData*)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    YTGabMessage *message = [self.gab messageAtIndex:row];
    BOOL sent = message.sent.boolValue;
    BOOL gabSent = self.gab.sent.boolValue;
    NSBubbleType type;
    
    if (sent && gabSent) {
        type = BubbleTypeMine2;
    } else if (sent && !gabSent) {
        type = BubbleTypeMine;
    } else if (!sent && gabSent) {
        type = BubbleTypeSomeoneElse2;
    } else if (!sent && !gabSent) {
        type = BubbleTypeSomeoneElse;
    }

    NSDate *localDate = [YTHelper localDateFromUtcDate:message.created_at];
    NSString *text;
    NSBubbleData *data;
    
    if (message.kind.integerValue == YTMessageKindText) {
        //is this ever used? TODO
        NSDictionary *messages = @{
            @"ERROR_SMS_DELIVERY": NSLocalizedString(@"Sorry, we couldn't deliver your message. Please make sure to enter correct phone number", nil),
            @"ERROR_SMS_PHOTO_DELIVERY": NSLocalizedString(@"Sorry, We couldn't deliver your message. Photo messages to unregistered users are not supported yet", nil)
        };
        
        text = message.content;
        if (messages[text] != nil) { text = messages[text]; }
        data = [NSBubbleData dataWithTextView:text date:localDate type:type];
    } else if (message.kind.integerValue == YTMessageKindPhoto) {
        data = [NSBubbleData dataWithImage:message.image date:localDate type:type];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [data.view addGestureRecognizer:singleTap];
        [data.view setUserInteractionEnabled:YES];
        data.view.tag = row;
        
    } else {
        data = [NSBubbleData dataWithTextView:@"" date:localDate type:type];
    }
    
    NSInteger status = message.status.integerValue;
    if (status == YTGabMessageStatusReady) {
        NSString *key = message.key;
        //TODO wtf is this deliveredmessage 
        NSDate *deliveredAt = [YTAppDelegate current].deliveredMessages[key];
        
        if (deliveredAt != nil) {
            NSInteger interval = [[NSDate date] timeIntervalSinceDate:deliveredAt];
            if (interval < 3) {
                data.status = NSLocalizedString(@"Delivered", nil);                
            } else {
                data.status = @"";
                [[YTAppDelegate current].deliveredMessages removeObjectForKey:key];
            }
        } else {
            data.status = @"";
        }
    } else if (status == YTGabMessageStatusDelivering) {
        data.status = NSLocalizedString(@"Delivering", nil);
    } else if (status == YTGabMessageStatusFailed) {
        data.status = NSLocalizedString(@"Failed. Tap to resend", nil);
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [data.view addGestureRecognizer:singleTap];
        [data.view setUserInteractionEnabled:YES];
        data.view.tag = row;
    }
    

    return data;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tableView tableView:self.tableView heightForRowAtIndexPath:indexPath];
}

- (void)singleTap:(UITapGestureRecognizer*)gesture
{
    UIView *view = [gesture.view hitTest:[gesture locationInView:gesture.view] withEvent:nil];
    NSInteger row = view.tag;
    YTGabMessage *object = [self.gab messageAtIndex:row];
    if(object.status.integerValue == YTGabMessageStatusFailed) {
        [object repostMessage];
    }
    else {
        NSString *secret = [object valueForKey:@"secret"];
        NSURL *baseUrl = [YTApiHelper baseUrl];
        NSString *urlString = [NSString stringWithFormat:@"%@images?secret=%@", baseUrl, secret];
        NSURL *url = [NSURL URLWithString:urlString];
        
        YTPhotoViewController *photoView = [[YTPhotoViewController alloc] initWithGabView:self url:url];
        [self presentViewController:photoView animated:YES completion:nil];
    }
}


# pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setBackgroundColor:[UIColor colorWithRed:0xed/255.0 green:0xec/255.0 blue:0xec/255.0 alpha:1]];
    
    self.inputView.image = [[YTHelper imageNamed:@"inputview3"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    self.inputView.textView.layer.cornerRadius = 10;
    self.inputView.textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.inputView.textView.layer.borderWidth = 1;  
    
    self.photoHelper = [[YTGabPhotoHelper alloc] initWithGabView:self];
    self.clueHelper = [[YTGabClueHelper alloc] initWithGabView:self];
    self.tagHelper = [[YTGabTagHelper alloc] initWithGabView:self];
 
    self.tableView.bubbleDataSource = self;
    self.tableView.snapInterval = 120;
    self.tableView.typingBubble = NSBubbleTypingTypeNobody;
    self.tableView.delegate = self;
    
    self.backgroundSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.backgroundSpinner setColor:[UIColor grayColor]];
    
    self.rowSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.rowSpinner setColor:[UIColor grayColor]];
    
    int spinnerSize = self.backgroundSpinner.bounds.size.height;
    int height = self.view.frame.size.height - spinnerSize - self.inputView.frame.size.height;
    self.backgroundSpinner.frame = CGRectMake((self.view.frame.size.width - spinnerSize)/2.0,
                                    height/2.0 - self.view.frame.origin.y, spinnerSize, spinnerSize);
    [self.view addSubview:self.backgroundSpinner];
    
    spinnerSize = self.rowSpinner.bounds.size.height;
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, spinnerSize + 7)];
    self.rowSpinner.frame = CGRectMake((self.view.frame.size.width - spinnerSize)/2.0,
                                    0, spinnerSize, spinnerSize);
    [self.footerView addSubview:self.rowSpinner];

    UITapGestureRecognizer *rec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    UISwipeGestureRecognizer *rec2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    rec2.direction = UISwipeGestureRecognizerDirectionDown;
    [self.tableView addGestureRecognizer:rec];
    [self.tableView addGestureRecognizer:rec2];
    
    self.navigationItem.rightBarButtonItems = nil;
    self.title = nil;
    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appActivated:) name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [self setupView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)updateGab
{
    [self.gab update:YES failure:^(id JSON) {
        if(!YTAppDelegate.current.reachability.isReachable) {
            [self stopSpinner];
        }
        else
            [self updateGab];
    }];
}

- (void)appActivated:(NSNotification*)note
{
    if(self.view.window && !self.friend)
        [self updateGab];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(self.gab) {
        [self showSpinner];
        
        [self updateGab];
        
        if(self.gab.messageCount != 0) {
            [self.tableView reloadData];
            [self scrollToFooter];
        }
        
        [self.gab clearUnread];
    }
    else {
        [self.inputView.textView becomeFirstResponder];
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

- (void)tapped
{
    [self.inputView.textView resignFirstResponder];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    //[self.inputView.textView resignFirstResponder];

}

- (void)keyboardWillShowHide:(NSNotification *)notification hide:(BOOL)hide
{
    /* copied from parent so we can animate the background spinner as needed*/
    /* also, don't animate anything if we are showing the tag helper */
    if(self.tagHelper.alertView.visible)
        return;
    
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	//UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGFloat keyboardY = [self.view convertRect:keyboardRect fromView:nil].origin.y;
                         if (hide) {
                             keyboardY = self.view.frame.size.height;
                             //  keyboardY += keyboardRect.size.height;
                         }
                         
                         CGRect inputViewFrame = self.inputView.frame;
                         self.inputView.frame = CGRectMake(inputViewFrame.origin.x,
                                                           keyboardY - inputViewFrame.size.height,
                                                           inputViewFrame.size.width,
                                                           inputViewFrame.size.height);
                         
                         UIEdgeInsets insets = UIEdgeInsetsMake(0.0f,
                                                                0.0f,
                                                                self.view.frame.size.height - self.inputView.frame.origin.y - self.inputView.bounds.size.height,
                                                                0.0f);
                         
                         self.tableView.contentInset = insets;
                         self.tableView.scrollIndicatorInsets = insets;
                         
                         int spinnerSize = self.backgroundSpinner.bounds.size.height;
                         int height = keyboardY - spinnerSize - self.inputView.frame.size.height;
                         self.backgroundSpinner.frame = CGRectMake((self.view.frame.size.width - spinnerSize)/2.0,
                                                                   height/2.0 - self.view.frame.origin.y, spinnerSize, spinnerSize);

                     }
                     completion:^(BOOL finished) {
                     }];
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
