//
//  YTGabViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>

#import <Base64/MF_Base64Additions.h>
#import <SDWebImage/UIImageView+WebCache.h>


#import "JSMessagesViewController.h"
#import "JSMessageInputView.h"
#import "NSString+JSMessagesView.h"

#import "YTGabViewController.h"
#import "YTApiHelper.h"
#import "YTAppDelegate.h"
#import "YTModelHelper.h"
#import "YTViewHelper.h"
#import "YTContactHelper.h"
#import "YTWebViewController.h"
#import "YTPhotoViewController.h"
#import "YTHelper.h"



@implementation YTGabViewController

# pragma mark Interface initialization methods

- (void)loadGab
{
    NSManagedObject *gab = [YTModelHelper gabForId:self.gabId];
    
    if ([[gab valueForKey:@"sent"] isEqualToNumber:@0]) {
        [self.clueHelper setupClueButton];
    }
    
    if ([YTAppDelegate current].usesSplitView) {
        [YTAppDelegate current].currentMainViewController.selectedGabId = self.gabId;
    }

    [self reloadData];
    
    if (self.navigationItem.hidesBackButton) {
        self.navigationItem.rightBarButtonItems = @[];
        [self.navigationItem setHidesBackButton:NO animated:YES];
    }
    
    BOOL gabSent = ![[gab valueForKey:@"sent"] isEqualToNumber:@0];
    
    if (!gabSent) {
        [self.inputView.sendButton setBackgroundImage:[[UIImage imageNamed:@"sendbtn_blue_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]                                    forState:UIControlStateNormal];
        [self.inputView.sendButton setBackgroundImage:[[UIImage imageNamed:@"sendbtn_blue_inactive"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]                                    forState:UIControlStateDisabled];
    }

}

- (void)reloadData
{
    NSManagedObject *gab = [YTModelHelper gabForId:self.gabId];
    NSString *title = [gab valueForKey:@"related_user_name"];
    BOOL hasTitle = title && [title length] > 0;
    BOOL sent = [[gab valueForKey:@"sent"] isEqualToNumber:@0];

    self.title = hasTitle ? title : @"???";
    [self.tagHelper setupTagButton:sent];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

- (void)updateSendButton
{
    [self.sendHelper updateButtons];
}

- (void)keyboardWillShowHide:(NSNotification *)notification hide:(BOOL)hide
{
    [super keyboardWillShowHide:notification hide:hide];
    [self.sendHelper keyboardWillShowHide:notification];
}

- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    [self.sendHelper sendPressed:sender withText:text];    
}

#pragma mark UIBubbleTableViewDataSource

- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    NSInteger count = [YTModelHelper messageCount:self.gabId];
    self.messages = [YTModelHelper messagesForGab:self.gabId];
    return count;
}

- (NSBubbleData*)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    NSManagedObject *gab = [YTModelHelper gabForId:self.gabId];
    NSManagedObject *object = self.messages[row];
    BOOL sent = ![[object valueForKey:@"sent"] isEqualToNumber:@0];
    BOOL gabSent = ![[gab valueForKey:@"sent"] isEqualToNumber:@0];
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

    NSDate *date = [object valueForKey:@"created_at"];
    NSDate *localDate = [YTHelper localDateFromUtcDate:date];
    NSString *text;
    UIImage *image;
    NSBubbleData *data;
    
    if ([object valueForKey:@"kind"] == [NSNumber numberWithInteger:YTMessageKindText]) {
        NSDictionary *messages = @{
            @"ERROR_SMS_DELIVERY": NSLocalizedString(@"Sorry, we couldn't deliver your message. Please make sure to enter correct phone number", nil),
            @"ERROR_SMS_PHOTO_DELIVERY": NSLocalizedString(@"Sorry, We couldn't deliver your message. Photo messages to unregistered users are not supported yet", nil)
        };
        text = [object valueForKey:@"content"];
        if (messages[text] != nil) { text = messages[text]; }
        data = [NSBubbleData dataWithText:text date:localDate type:type];
    } else if ([object valueForKey:@"kind"] == [NSNumber numberWithInteger:YTMessageKindPhoto]) {
        image = [YTModelHelper imageForMessage:object];
        data = [NSBubbleData dataWithImage:image date:localDate type:type];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [data.view addGestureRecognizer:singleTap];
        [data.view setUserInteractionEnabled:YES];
        data.view.tag = row;
        
    } else {
        data = [NSBubbleData dataWithText:@"" date:localDate type:type];
    }
    
    NSInteger status = [[object valueForKey:@"status"] integerValue];
    if (status == MESSAGE_STATUS_READY) {
        NSString *key = [object valueForKey:@"key"];
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
    } else if (status == MESSAGE_STATUS_DELIVERING) {
        data.status = NSLocalizedString(@"Delivering", nil);
    } else if (status == MESSAGE_STATUS_FAILED) {
        data.status = NSLocalizedString(@"Failed", nil);
    }
    

    return data;
}


- (void)singleTap:(UITapGestureRecognizer*)gesture
{
    UIView *view = [gesture.view hitTest:[gesture locationInView:gesture.view] withEvent:nil];
    NSInteger row = view.tag;
    NSManagedObject *object = self.messages[row];
    NSString *secret = [object valueForKey:@"secret"];
    NSURL *baseUrl = [YTApiHelper baseUrl];
    NSString *urlString = [NSString stringWithFormat:@"%@images?secret=%@", baseUrl, secret];
    NSURL *url = [NSURL URLWithString:urlString];
    
    YTPhotoViewController *photoView = [[YTPhotoViewController alloc] initWithGabView:self url:url];
    [self presentViewController:photoView animated:YES completion:nil];
}


# pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //[self setBackgroundColor:[UIColor colorWithRed:0xfc/255.0 green:0xfc/255.0 blue:0xfc/255.0 alpha:1]];
    [self setBackgroundColor:[UIColor colorWithRed:0xed/255.0 green:0xec/255.0 blue:0xec/255.0 alpha:1]];
    
    self.inputView.image = [[UIImage imageNamed:@"inputview3.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    self.inputView.textView.layer.cornerRadius = 10;
    self.inputView.textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.inputView.textView.layer.borderWidth = 1;
    

    
    self.photoHelper = [[YTGabPhotoHelper alloc] initWithGabView:self];
    self.clueHelper = [[YTGabClueHelper alloc] initWithGabView:self];
    self.deleteHelper = [[YTGabDeleteHelper alloc] initWithGabView:self];
    self.sendHelper = [[YTGabSendHelper alloc] initWithGabView:self];
    self.tagHelper = [[YTGabTagHelper alloc] initWithGabView:self];
 
    self.tableView.bubbleDataSource = self;
    self.tableView.snapInterval = 120;
    self.tableView.typingBubble = NSBubbleTypingTypeNobody;
    
    if (self.gabId) {
        [self loadGab];
        [YTApiHelper autoSync:YES];
    } else {
        self.title = NSLocalizedString(@"New message", nil);
        
        if (![[YTAppDelegate current] usesSplitView]) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
            self.navigationItem.hidesBackButton = YES;
        }
    }

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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

- (void)dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
