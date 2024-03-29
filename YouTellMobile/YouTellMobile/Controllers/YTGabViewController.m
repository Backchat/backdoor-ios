//
//  YTGabViewController.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//LINREVIEW: refactor contactWidget out of Sendhelper into here

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
#import "YTContactHelper.h"
#import "YTWebViewController.h"
#import "YTPhotoViewController.h"
#import "YTHelper.h"
#import "YTFBHelper.h"
#import "YTGabMessage.h"
#import "YTNewGabViewController.h"
#import "YTGPPHelper.h"

@interface YTGabViewController ()
@property (nonatomic, retain) NSArray* messages;
@end

//LINREVIEW this is actually the code for queuing and sending messages
@interface YTGabViewController ()
@property (nonatomic, retain) NSMutableArray* queuedMessages;
@property (nonatomic, assign) bool ongoingRequest;

- (void)queueMessage:(NSString*)text ofKind:(NSInteger)kind;
- (void)processMessage:(NSManagedObject*)message;

- (void)sendMessage:(NSManagedObject*)message;

- (NSManagedObject*)addMessageLocally:(YTGabMessage*)message;

- (void)handleNextQueuedMessage;
- (bool)fakeGab;
@end

@implementation YTGabViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.queuedMessages = [[NSMutableArray alloc] init];
        self.messages = [[NSMutableArray alloc] init];
        self.ongoingRequest = false;
        self.gab = nil;
    }
    return self;
}

# pragma mark Interface initialization methods

- (void)hideContactWidget
{    
    if (self.sendHelper.contactWidget.hidden == YES) {
        return;
    }
        
    UIView* contactWidget = self.sendHelper.contactWidget;
    [UIView animateWithDuration:0.5 animations:^{
        contactWidget.frame = CGRectMake(0, -contactWidget.frame.size.height, contactWidget.frame.size.width, contactWidget.frame.size.height);
    } completion:^(BOOL finished) {
        contactWidget.hidden = YES;
    }];
    
    self.navigationItem.rightBarButtonItems = @[];
    [self.navigationItem setHidesBackButton:NO animated:YES];
}


- (bool)fakeGab
{
    if(self.gab == nil) return true;
    NSNumber* g_id = [self.gab valueForKey:@"id"];
    return g_id.integerValue < 0;
}

- (void)setGabId:(NSNumber*)gabId
{
    NSLog(@"set gab id: %@", gabId);
    self.gab = [YTModelHelper gabForId:gabId];
    
    [self reloadData];
}

- (void)createAndSetGabWithData:(NSDictionary*)data
{
    self.gab = [YTModelHelper createOrUpdateGab:data];

    // Remove New Gab view from the stack, so the back button points to the Main view again
    NSMutableArray *views = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    for (UIViewController *c in views) {
        if ([c isKindOfClass:[YTNewGabViewController class]]) {
            [views removeObject:c];
            break;
        }
    }
    self.navigationController.viewControllers = views;
    
    // Replace Cancel button with standard back button
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.hidesBackButton = NO;
    
    // FIXME: remove contact widget
    [self hideContactWidget];
    
    [[YTContactHelper sharedInstance] filterRandomizedFriends];
    //[YTViewHelper refreshViews];  Called by filterRandomizedFriends
}

- (void)loadGab
{
    if(self.gab) {
    
        if ([[self.gab valueForKey:@"sent"] isEqualToNumber:@0]) {
            [self.clueHelper setupClueButton];
        }
        
        if ([YTAppDelegate current].usesSplitView) {
            [YTAppDelegate current].currentMainViewController.selectedGabId = [self.gab valueForKey:@"id"];
        }
        
        [YTViewHelper refreshViews];
        
        BOOL gabSent = ![[self.gab valueForKey:@"sent"] isEqualToNumber:@0];
        
        if (!gabSent) {
            [self.inputView.sendButton setBackgroundImage:[[YTHelper imageNamed:@"sendbtn_blue_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]                                    forState:UIControlStateNormal];
            [self.inputView.sendButton setBackgroundImage:[[YTHelper imageNamed:@"sendbtn_blue_inactive"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]                                    forState:UIControlStateDisabled];
        }
    }
    else {
        self.title = NSLocalizedString(@"New Message", nil);
        
        if (![[YTAppDelegate current] usesSplitView]) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
            self.navigationItem.hidesBackButton = YES;
        }
    }

}

- (void)reloadData
{
    if(self.gab) {
        id gab_id = [self.gab valueForKey:@"id"];
        
        self.messages = [YTModelHelper messagesForGab:gab_id];
        NSLog(@"reload screen with messages %d", self.messages.count);

        NSString *title = [self.gab valueForKey:@"related_user_name"];
        BOOL hasTitle = title && [title length] > 0;
        BOOL sent = [[self.gab valueForKey:@"sent"] isEqualToNumber:@0];
        
        self.title = hasTitle ? title : @"???";
        
        [self.tagHelper setupTagButton:sent];
        
        [self.tableView reloadData];
        
        [YTApiHelper clearUnread:gab_id];

        [self scrollToBottomAnimated:YES];
    }
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
    return self.messages.count;
}

- (NSBubbleData*)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    NSManagedObject *object = self.messages[row];
    BOOL sent = ![[object valueForKey:@"sent"] isEqualToNumber:@0];
    BOOL gabSent = ![[self.gab valueForKey:@"sent"] isEqualToNumber:@0];
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
        data = [NSBubbleData dataWithTextView:text date:localDate type:type];
    } else if ([object valueForKey:@"kind"] == [NSNumber numberWithInteger:YTMessageKindPhoto]) {
        image = [YTModelHelper imageForMessage:object];
        data = [NSBubbleData dataWithImage:image date:localDate type:type];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [data.view addGestureRecognizer:singleTap];
        [data.view setUserInteractionEnabled:YES];
        data.view.tag = row;
        
    } else {
        data = [NSBubbleData dataWithTextView:@"" date:localDate type:type];
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
    
    self.inputView.image = [[YTHelper imageNamed:@"inputview3"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    self.inputView.textView.layer.cornerRadius = 10;
    self.inputView.textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.inputView.textView.layer.borderWidth = 1;
    

    
    self.photoHelper = [[YTGabPhotoHelper alloc] initWithGabView:self];
    self.clueHelper = [[YTGabClueHelper alloc] initWithGabView:self];
    self.sendHelper = [[YTGabSendHelper alloc] initWithGabView:self];
    self.tagHelper = [[YTGabTagHelper alloc] initWithGabView:self];
 
    self.tableView.bubbleDataSource = self;
    self.tableView.snapInterval = 120;
    self.tableView.typingBubble = NSBubbleTypingTypeNobody;
    
    [self loadGab];

    if(![self fakeGab] && [[self.gab valueForKey:@"needs_update"] boolValue])
        [YTApiHelper syncGabWithId:[self.gab valueForKey:@"id"]];
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
    [[Mixpanel sharedInstance] track:@"Cancelled Thread Compose"];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) updateState {
    [YTViewHelper refreshViews];
    
    [self scrollToBottomAnimated:YES];
}

- (void)queueMessage:(NSString*)text ofKind:(NSInteger)kind
{
    /* everything is executed on the main thread. we have no need for a lock */
    YTGabMessage* message = [YTGabMessage messageWithContent:text andKind:kind];
    
    /*is this a new gab window? if it is, we don't have a gab.
     1. We opened from main gab a gab -> we have a gabId -> we have a gab
     2. We opened from an APN -> we have a gabID -> we have a gab
     3. We opened from new gab -> we have a receiver -> we don't have a gab
     4. we opened from main gab a friend or a featured -> we have a recv. -> we dont' have a gab
    */

    if(!self.gab) {
        //first message!!
        //we need to fake up a gab, too.
        NSDictionary* contact = self.sendHelper.contactWidget.selectedContact;
        NSNumber* val = [YTModelHelper nextFakeGabId];
        
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString* dateStr = [formatter stringFromDate:[NSDate date]];

        NSString* messageText = [text copy];
        if(kind == YTMessageKindPhoto)
            messageText = @"";
        
        //LINREVIEW dry with maincontroller
        NSString* avatar_url = @"";

        if ([contact[@"type"] isEqualToString:@"facebook"]) {
            avatar_url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", contact[@"value"]];
        } else if ([contact[@"type"] isEqualToString:@"gpp"]) {
            avatar_url = [NSString stringWithFormat:@"https://profiles.google.com/s2/photos/profile/%@?sz=50", contact[@"value"]];
        }
        
        NSDictionary* gabData = @{@"related_user_name": contact[@"name"],
                                  @"related_avatar": avatar_url,
                                  @"sent":@true,
                                  @"clue_count":@0,
                                  @"id":val, @"total_count":@1, @"updated_at":dateStr,
                                  @"unread_count":@0, @"content_summary":messageText};
        
        [self createAndSetGabWithData:gabData];
    }
    
    NSManagedObject* messageObject = [self addMessageLocally:message];
    
    if(!self.ongoingRequest) {
        [self processMessage:messageObject];
    }
    else {
        [self.queuedMessages addObject:messageObject];
    }
}

- (void)handleNextQueuedMessage
{
    if([self.queuedMessages count] != 0) {
        NSManagedObject* message = (NSManagedObject*)[self.queuedMessages objectAtIndex:0];
        [self.queuedMessages removeObjectAtIndex:0];
        [self processMessage:message];
    }
}

- (NSManagedObject*)addMessageLocally:(YTGabMessage*)message
{    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *key = [YTHelper randString:8];
    
    params[@"content"] = message.content;
    params[@"kind"] = [NSNumber numberWithInteger:message.kind];
    params[@"key"] = key;
    params[@"gab_id"] = [self.gab valueForKey:@"id"];
    
    NSManagedObject *lastMessage = [YTModelHelper messagesForGab:[self.gab valueForKey:@"id"]].lastObject;
    NSDate* date;
    if(!lastMessage) {
        //very first message.
        date = [NSDate date];
    }
    else {
        date = [lastMessage valueForKey:@"created_at"];
        date = [date dateByAddingTimeInterval:5];
    }
    params[@"created_at"] = date;

    NSManagedObject* messageObject = [YTModelHelper createMessage:params];

    [YTViewHelper refreshViews];
    
    return messageObject;
}

- (void)processMessage:(NSManagedObject*)message
{
    if (![self fakeGab]) {
        [self sendMessage:message];
    }
    else {
        //we need to start a new convo.
        NSDictionary *contact = self.sendHelper.contactWidget.selectedContact;

        if (![contact[@"type"] isEqualToString:@"facebook"] && ![contact[@"type"] isEqualToString:@"gpp"]) {
            //LINREVIEW note that this never occurs right now because the contact picker doesn't allow
            //non-fb people to show up
        }
        else {
            [[Mixpanel sharedInstance] track:@"Created Thread"];
            
            self.ongoingRequest = true;
            NSMutableDictionary* params = [[NSMutableDictionary alloc] init];

            [params setValue:@{@"content": [message valueForKey:@"content"],
             @"kind": [message valueForKey:@"kind"],
             @"key": [message valueForKey:@"key"]} forKey:@"message"];
            if(contact[@"id"]) {
                [params setValue:@{@"id": contact[@"id"]} forKey:@"friendship"];
            }
            else {
                [params setValue:@{@"id": contact[@"featured_id"]} forKey:@"featured"];
            }
            [YTApiHelper sendJSONRequestToPath:@"/gabs" method:@"POST" params:params
                                       success:^(id JSON) {
                                           //make it real!
                                           id new_id = JSON[@"gab"][@"id"];
                                           id old_id = [self.gab valueForKey:@"id"];
                                           for(NSManagedObject* to in self.queuedMessages) {
                                               [to setValue:new_id forKey:@"gab_id"];
                                           }
                                           [YTApiHelper deleteGab:old_id success:nil];
                                           
                                           self.gab = [YTModelHelper createOrUpdateGab:JSON[@"gab"]];
                                           [self loadGab];
                                           
                                           [YTViewHelper refreshViews];
                                           self.ongoingRequest = false;
                                           [self handleNextQueuedMessage];
                                           
                                       }
             
                                       failure:^(id JSON) {
                                           [YTViewHelper refreshViews];                                           
                                           self.ongoingRequest = false;
                                           [self handleNextQueuedMessage];
                                           
                                       }];
        }
    }
}

//TODO DRY this up and make it less ugly. we shouldn't use a delay and we should
//add a block to the main thread

- (void) showFBRequest
{
    NSDictionary *contact = self.sendHelper.contactWidget.selectedContact;
    [YTFBHelper presentRequestDialogWithContact:contact[@"value"] complete:^{
        [self dismiss];
    }];
}

- (void) showGPPRequest
{
    [[YTGPPHelper sharedInstance] presentShareDialog];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{    
    //at this point, some number of messages may be queued.
    //we need to empty the unsent queue and cache messages.
    //LINREVIEW is that the right UX?
        
    [self.queuedMessages removeAllObjects];
    [YTApiHelper deleteGab:[self.gab valueForKey:@"id"] success:nil];
    [YTViewHelper refreshViews];
    
    if(buttonIndex == 1) {
        //"invite"
        [[Mixpanel sharedInstance] track:@"Agreed To Invite Friend Instead Of Sending Message"];
        
        if ([[YTAppDelegate current].userInfo[@"provider"] isEqualToString:@"facebook"]) {
            [self.inputView.textView resignFirstResponder]; //LINREVIEW brittle, no abstraction here
            
            //a half second delay is needed because of animation issues
            [self performSelector:@selector(showFBRequest) withObject:nil afterDelay:0.5];
            
            [[Mixpanel sharedInstance] track:@"Agreed To Invite Facebook Friend Instead Of Sending Message"];

        
        } else {
            //show the GPP generalized share
            //TODO target the specific user
            //a half second delay is needed because of animation issues
            [self performSelector:@selector(showGPPRequest) withObject:nil afterDelay:0.5];
            
            [[Mixpanel sharedInstance] track:@"Agreed To Invite Google+ Friend Instead Of Sending Message"];

//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Sending messages to unregistered Google+ friends is not supported yet", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil];
//            [alert show];
            [self dismiss];            
        }
    }
    else {
        [[Mixpanel sharedInstance] track:@"Disagreed To Invite Friend Instead Of Sending Message"];

        [self dismiss];
    }

}

- (void)sendMessage:(NSManagedObject*)message
{
    NSDictionary* params = [message dictionaryWithValuesForKeys:message.entity.attributesByName.allKeys];

    NSString* key = params[@"key"];
    NSNumber* gab_id = [message valueForKey:@"gab_id"];
    
    self.ongoingRequest = true;

    [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@/messages", gab_id]
                                method:@"POST" params:params
                               success:^(id JSON) {
                                   [YTAppDelegate current].deliveredMessages[key] = [NSDate date];                                   
                                   
                                   [YTModelHelper updateMessage:JSON[@"message"]];
                                   [self updateState];
                                   
                                   NSNumber *gabSent = [NSNumber numberWithBool:![[self.gab valueForKey:@"sent"] isEqualToNumber:@0]];

                                   [Flurry logEvent:@"Sent_Message" withParameters:@{@"kind":params[@"kind"]}];
                                   [[Mixpanel sharedInstance] track:@"Sent Message" properties:@{@"Anonymous": gabSent}];
                                   
                                   self.ongoingRequest = false;
                                   [self handleNextQueuedMessage];
                               }
     
                               failure:^(id JSON) {
                                   [YTModelHelper failMessage:key];
                                   [YTViewHelper refreshViews];
                                   
                                   self.ongoingRequest = false;
                                   [self handleNextQueuedMessage];
                                   
                               }];
}

@end
