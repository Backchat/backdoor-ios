//
//  YTFBHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <FacebookSDK/Facebook.h>

#import <FlurrySDK/Flurry.h>
#import <Mixpanel.h>

#import "YTAppDelegate.h"
#import "YTFBHelper.h"
#import "YTAppDelegate.h"
#import "YTLoginViewController.h"
#import "YTViewHelper.h"
#import "YTApiHelper.h"
#import "YTContactHelper.h"
#import "YTModelHelper.h"
#import "YTHelper.h"
#import "YTConfig.h"

@implementation YTFBHelper

+ (void)setup
{
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [YTFBHelper openSession];
    }
}

+ (void)sessionOpened
{
    [YTApiHelper resetUserInfo];
    
    [Flurry logEvent:@"Signed_In_With_Facebook"];
    [[Mixpanel sharedInstance] track:@"Signed In With Facebook"];
    
    YTAppDelegate *delegate = [YTAppDelegate current];
    delegate.userInfo[@"provider"] = @"facebook";
    delegate.userInfo[@"access_token"] = FBSession.activeSession.accessTokenData.accessToken;

    [YTFBHelper fetchUserData];
    [YTViewHelper hideLogin];
}

+ (void)sessionStateChanged:(FBSession*)session state:(FBSessionState)state error:(NSError*)error
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    
    switch(state) {
        case FBSessionStateOpen:
            [YTFBHelper sessionOpened];
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [delegate.navController popToRootViewControllerAnimated:NO];
            [FBSession.activeSession closeAndClearTokenInformation];
            [YTViewHelper showLogin];
            break;
        default:
            break;
    }
    
    if (error) {
        NSLog(@"Facebook session error: %@", error.localizedDescription);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Facebook login error", nil) message:NSLocalizedString(@"Unexpected error happened. Try again later.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

+ (void)fetchUserData
{
    FBRequest *request = [FBRequest requestForGraphPath:@"/me"];
    YTAppDelegate *delegate = [YTAppDelegate current];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        if ([result[@"gender"] isEqualToString:@"male"]) {
            [Flurry setGender:@"m"];
            [[Mixpanel sharedInstance].people set:@"Gender" to:@"Male"];

        } else if ([result[@"gender"] isEqualToString:@"female"]) {
            [Flurry setGender:@"f"];
            [[Mixpanel sharedInstance].people set:@"Gender" to:@"Female"];
        }
        
        NSInteger age = [YTHelper ageWithBirthdayString:result[@"birthday"] format:@"MM/dd/yyyy"];
        
        if (age > 0) {
            [Flurry setAge:age];
            [[Mixpanel sharedInstance].people set:@"Age" to:[NSNumber numberWithInt:age]];
        }
        [[Mixpanel sharedInstance].people set:@{@"$email": result[@"email"], @"$first_name": result[@"first_name"], @"$last_name": result[@"last_name"]}];
        [[Mixpanel sharedInstance].people setOnce:@{@"$created": [NSDate date]}];
        
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"Logged in as %@", result[@"name"]);
            delegate.userInfo[@"fb_data"] = [NSMutableDictionary dictionaryWithDictionary:result];
            [YTModelHelper changeStoreId:result[@"email"]];
            [YTContactHelper sharedInstance].updateFriends = YES;
            [YTApiHelper autoSync:NO];
            [YTFBHelper fetchFamily];
            [YTFBHelper fetchInterests];
            [YTFBHelper fetchLikes];
            [YTApiHelper getFeaturedUsers];
        }];
    }];
}

+ (void)fetchFriends
{
    FBRequest *request = [FBRequest requestForMyFriends];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[YTContactHelper sharedInstance] loadFacebookFriends:result[@"data"]];
        }];

    }];
}

+ (void)fetchFamily
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    FBRequest *request = [FBRequest requestForGraphPath:@"/me/family"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            delegate.userInfo[@"fb_data"][@"family"] = result[@"data"];
        }];
    }];
}

+ (void)fetchInterests
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    FBRequest *request = [FBRequest requestForGraphPath:@"/me/interests"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            delegate.userInfo[@"fb_data"][@"interests"] = result[@"data"];
        }];
    }];
}

+ (void)fetchLikes
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    FBRequest *request = [FBRequest requestForGraphPath:@"/me/likes"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            delegate.userInfo[@"fb_data"][@"likes"] = result[@"data"];
        }];
    }];
}

+ (void)openSession
{
    NSArray *perms = @[@"email", @"user_birthday", @"user_education_history", @"user_work_history", @"user_location", @"user_relationships", @"user_likes", @"user_interests"];


    
   FBSession *session = [[FBSession alloc] initWithPermissions:perms];
   [FBSession setActiveSession:session];
    [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [YTFBHelper sessionStateChanged:session state:status error:error];
        }];
        
    }];
    
    return;
    
    [FBSession openActiveSessionWithReadPermissions:perms allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [YTFBHelper sessionStateChanged:session state:state error:error];
        }];
        
    }];
}

+ (void)closeSession
{
    [FBSession.activeSession closeAndClearTokenInformation];
}

+ (BOOL)handleOpenUrl:(NSURL*)url
{
    return [FBSession.activeSession handleOpenURL:url];
}

+ (NSDictionary*)parseURLParams:(NSString*)query
{
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val = [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *key = kv[0];
        params[key] = val;
    }
    return params;
}

+ (void)presentFeedDialogCallback
{
    NSDictionary *params = @{
        @"name": NSLocalizedString(@"Backdoor", nil),
        @"caption": NSLocalizedString(@"Send and receive anonymous messages", nil),
        @"description": NSLocalizedString(@"Backdoor is a new application for iOS that allows sending and receiving anonymous text and photo messages.", nil),
        @"link": CONFIG_SHARE_URL,
        @"picture": @"https://s3.amazonaws.com/backdoor_images/icon_114x114.png"
    };
    
    [FBWebDialogs presentFeedDialogModallyWithSession:nil parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
        
        if (error != nil) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        if (result == FBWebDialogResultDialogNotCompleted || [resultURL.absoluteString isEqualToString:@"fbconnect://success"]) {
            return;
        }
        
        [YTApiHelper getFreeCluesWithReason:@"fbshare"];
        
        [[Mixpanel sharedInstance] track:@"Shared On Facebook"];
    }];

}

+ (void)presentFeedDialog
{
    /*
    if (![[YTAppDelegate current].userInfo[@"provider"] isEqualToString:@"facebook"]) {
        return;
    }
     */
    
    if (!FBSession.activeSession.isOpen) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"You need to log in with Facebook to use this feature", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if ([FBSession.activeSession.permissions containsObject:@"publish_actions"]) {
        [YTFBHelper presentFeedDialogCallback];
        return;
    }
    
    [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:^(FBSession *session, NSError *error) {
        
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        [YTFBHelper presentFeedDialogCallback];
    }];
}

+ (void)presentRequestDialogWithContact:(NSString*)contact complete:(void(^)())complete
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    if (contact) {
        params[@"to"] = contact;
    }
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil message:NSLocalizedString(@"Message me anything you want anonymously with Backdoor.  Backdoor Me!", nil)  title:nil  parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {        
        if (complete) {
            complete();
        }
        
        if (error != nil) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        if (result == FBWebDialogResultDialogNotCompleted || [resultURL.absoluteString isEqualToString:@"fbconnect://success"]) {
            [[Mixpanel sharedInstance] track:@"Cancelled Inviting Friend"];
            [[Mixpanel sharedInstance] track:@"Cancelled Inviting Friend On Facebook"];

            return;
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Your invitation has been sent", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
      
        [alert show];
        
        [YTApiHelper getFreeCluesWithReason:@"fbinvite"];

        [[Mixpanel sharedInstance] track:@"Invited Friend On Facebook"];
        [[Mixpanel sharedInstance] track:@"Invited Friend"];
    }];
}

@end
