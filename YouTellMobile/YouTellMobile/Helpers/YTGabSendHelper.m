//
//  YTGabSendHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Base64/MF_Base64Additions.h>
#import <NSString+JSMessagesView.h>
#import <Facebook-iOS-SDK/FacebookSDK/FacebookSDK.h>

#import "YTGabSendHelper.h"
#import "YTGabViewController.h"
#import "YTContactWidget.h"
#import "YTApiHelper.h"
#import "YTAppDelegate.h"
#import "YTViewHelper.h"
#import "YTHelper.h"
#import "YTModelHelper.h"
#import "YTFBHelper.h"
#import "YTAppDelegate.h"


@implementation YTGabSendHelper

- (id)initWithGabView:(YTGabViewController*)gabView
{
    self = [super init];
    if (!self) {
        return self;
    }
    self.gabView = gabView;
    
    CGRect contactWidgetFrame = CGRectMake(0, 0, self.gabView.view.bounds.size.width, 44);
    CGRect contactTableFrame = CGRectMake(0, 44, self.gabView.view.bounds.size.width, self.gabView.view.frame.size.height - contactWidgetFrame.size.height - self.gabView.inputView.frame.size.height);
    
    self.contactTable = [[UITableView alloc] initWithFrame:contactTableFrame style:UITableViewStylePlain];
    self.contactTable.hidden = YES;
    self.contactTable.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contactTable.backgroundColor = [UIColor clearColor];
    
    self.contactWidget = [[YTContactWidget alloc] initWithFrame:contactWidgetFrame tableView:self.contactTable];
    self.contactWidget.delegate = self;
    self.contactWidget.hidden = !!self.gabView.gabId;
    self.contactWidget.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self.gabView.view addSubview:self.contactTable];
    [self.gabView.view addSubview:self.contactWidget];
    
    [self updateButtons];

    
    return self;
}


- (void)sendMessageCallback:(NSDictionary *)receiverData
{
    //[self.gabView.inputView.textView resignFirstResponder];
    [self.gabView.inputView.textView setText:nil];
    [self.gabView textViewDidChange:self.gabView.inputView.textView];
   
    [YTApiHelper sendMessage:self.content kind:[NSNumber numberWithInteger:self.kind] receiverData:receiverData success:^(id JSON) {
        
        if (!self.gabView.gabId) {
            self.gabView.gabId = JSON[@"gab_id"];
            [self.gabView loadGab];
        }
        
        
        if (self.contactWidget != nil) {
            [UIView animateWithDuration:0.5 animations:^{
                self.contactWidget.frame = CGRectMake(0, -self.contactWidget.frame.size.height, self.contactWidget.frame.size.width, self.contactWidget.frame.size.height);
            } completion:^(BOOL finished) {
                self.contactWidget.hidden = YES;
                self.contactWidget = nil;
            }];
        };
        

        [YTViewHelper refreshViews];
        
        [self.gabView scrollToBottomAnimated:YES];
        
    }];
}

- (void)sendMessage
{
    if (self.gabView.gabId) {
        return [self sendMessageCallback:[self receiverData]];
    }
    
    if (!self.contactWidget || !self.contactWidget.selectedContact) {
        return;
    }
    
    NSDictionary *contact = self.contactWidget.selectedContact;
    if (![contact[@"type"] isEqualToString:@"facebook"] && ![contact[@"type"] isEqualToString:@"gpp"]) {
        return [self sendMessageCallback:[self receiverData]];
    }
    
    [YTApiHelper checkUid:contact[@"value"] success:^(id JSON) {
        if ([JSON[@"uid_exists"] isEqualToString:@"yes"]) {
            return [self sendMessageCallback:[self receiverData]];
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New message", nil) message:NSLocalizedString(@"Your friend does not have a Backdoor account.  Would you like to send an invite?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Invite", nil), nil];
        [alert show];
        /*
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: NSLocalizedString(@"New message", nil)
                              message: NSLocalizedString(@"Please enter phone number of your friend", nil)
                              delegate: nil
                              cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                              otherButtonTitles: NSLocalizedString(@"Send", nil), nil
                              ];
        
        alert.delegate = self;
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        UITextField *alertTextField = [alert textFieldAtIndex:0];
        alertTextField.keyboardType = UIKeyboardTypeNumberPad;
        alertTextField.text = [YTModelHelper phoneForUid:contact[@"value"]];
        alertTextField.delegate = self;
        
        [alert show];
         */
    }];
}

- (void)setTextContent:(NSString *)text
{
    self.content = text;
    self.kind = YTMessageKindText;
}

- (void)setPhotoContent:(UIImage *)image
{
    NSData *data = UIImageJPEGRepresentation(image, 0.85);
    self.content = [data base64String];
    self.kind = YTMessageKindPhoto;
}

# pragma mark UIAlertViewDelegate methods

- (void)sendRequest
{
    if ([[YTAppDelegate current].userInfo[@"provider"] isEqualToString:@"facebook"]) {
        
        NSDictionary *contact = self.contactWidget.selectedContact;

        [YTFBHelper presentRequestDialogWithContact:contact[@"value"] complete:^{
            [self.gabView dismiss];
        }];
        
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Sending messages to unregistered Google+ friends is not supported yet", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    

    [self performSelector:@selector(sendRequest) withObject:nil afterDelay:0.5];
    
    /*
    UITextField *field = [alertView textFieldAtIndex:0];
    [field resignFirstResponder];
    
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    NSMutableDictionary *receiverData = [NSMutableDictionary dictionaryWithDictionary:[self receiverData]];
    
    [YTModelHelper setPhoneForUid:receiverData[@"receiver_uid"] phone:field.text];
    receiverData[@"related_phone"] = field.text;
   
    [self sendMessageCallback:receiverData];
     */
}
/*
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    return [[alertView textFieldAtIndex:0].text length] > 8;
}
*/

# pragma mark YTContactsViewDelegate methods

- (void)changedSelectedContact:(NSDictionary *)contact
{
    [self updateButtons];
}

- (void)showContactViewController:(YTContactsViewController*)contactViewController
{
    if ([YTAppDelegate current].usesSplitView) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:contactViewController];
        [self.popover presentPopoverFromRect:self.contactWidget.frame inView:self.gabView.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.gabView.navigationController pushViewController:contactViewController animated:YES];
    }
}

- (void)hideContactViewController
{
    if ([YTAppDelegate current].usesSplitView) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self.gabView.navigationController popViewControllerAnimated:YES];
    }
}


# pragma mark UITextViewDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    static NSCharacterSet *digitSet = nil;
    
    if (!digitSet) {
        digitSet = [NSCharacterSet decimalDigitCharacterSet];
    }
    
    if (string.length == 0) {
        return YES;
    }
    
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:newString];
    
    return [digitSet isSupersetOfSet:set];
}

- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    [self setTextContent:text];
    [self sendMessage];
}


- (void)updateButtons
{
    self.gabView.inputView.sendButton.enabled = (([self.gabView.inputView.textView.text trimWhitespace].length > 0) && [self selectedContact]);
    
    self.gabView.inputView.cameraButton.enabled = [self selectedContact];
}

- (void)keyboardWillShowHide:(NSNotification *)notification
{
    int factor = ([notification name] == UIKeyboardWillShowNotification) ? -1 : 1;
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect kbFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbFrame = [self.gabView.view convertRect:kbFrame fromView:self.gabView.view.window];
    CGRect oldRect = self.contactTable.frame;
    CGRect newRect = CGRectMake(oldRect.origin.x, oldRect.origin.y, oldRect.size.width, (oldRect.size.height + (kbFrame.size.height * factor)));
    self.contactTable.frame = newRect;
}

- (BOOL)selectedContact
{
    if (self.gabView.gabId) {
        return YES;
    }
    
    if (self.contactWidget.selectedContact) {
        return YES;
    }
    
    return NO;
}

- (NSDictionary *)receiverData
{

    if (self.gabView.gabId) {
        return @{@"gab_id": self.gabView.gabId};
    } else if (self.contactWidget.selectedContact) {
        NSDictionary *contact = self.contactWidget.selectedContact;
        NSMutableDictionary *ret = [NSMutableDictionary new];

        ret[@"related_user_name"] = contact[@"name"];
        ret[@"receiver_phone"] = ([contact[@"type"] isEqualToString:@"phone"] ? contact[@"value"] : @"");
        ret[@"receiver_email"] = ([contact[@"type"] isEqualToString:@"email"] ? contact[@"value"] : @"");
        ret[@"receiver_fb_id"] =   ([contact[@"type"] isEqualToString:@"facebook"] ? contact[@"value"] : @"");
        ret[@"receiver_gpp_id"] =   ([contact[@"type"] isEqualToString:@"gpp"] ? contact[@"value"] : @"");
        return ret;
    };
    
    return nil;
}

@end
