//
//  YTFBHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <FacebookSDK/Facebook.h>

#import <FlurrySDK/Flurry.h>
#import <Mixpanel.h>
#import <Instabug/Instabug.h>

#import "YTAppDelegate.h"
#import "YTFBHelper.h"
#import "YTAppDelegate.h"
#import "YTLoginViewController.h"
#import "YTViewHelper.h"
#import "YTApiHelper.h"
#import "YTModelHelper.h"
#import "YTHelper.h"
#import "YTConfig.h"
#import "YTSocialHelper.h"

@interface YTFBHelper ()
+ (void)sessionStateChanged:(FBSession*)session state:(FBSessionState)state error:(NSError*)error;
+ (void)createSession;
+ (NSArray*) perms;
@end

@implementation YTFBHelper
+ (void) fireFailedLogin
{
    [[NSNotificationCenter defaultCenter] postNotificationName:YTSocialLoginFailed
                                                        object:nil];
}

+ (void) fireLoginSuccess:(FBSession*) session
{
    FBAccessTokenData* token_data = FBSession.activeSession.accessTokenData;
    if(!token_data) {
        [YTFBHelper fireFailedLogin];
        return;
    }
    
    [Flurry logEvent:@"Signed_In_With_Facebook"];
    [[Mixpanel sharedInstance] track:@"Signed In With Facebook"];
    
    NSString* accessToken = token_data.accessToken;
    
    NSDictionary* dict = 
    @{YTSocialLoggedInAccessTokenKey: accessToken,
      YTSocialLoggedInProviderKey: [NSNumber numberWithInteger:YTSocialProviderFacebook]};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YTSocialLoggedIn
                                                        object:nil
                                                      userInfo:dict];
}


/* simply reauthenticate. we KNOW they must have authed before. any failure here we kick to the
 not logged in state. */
+ (void)reauth {
    [YTFBHelper createSession];
    [FBSession openActiveSessionWithReadPermissions:[YTFBHelper perms]
                                       allowLoginUI:NO
                                  completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                      switch(state) {
                                          case FBSessionStateOpen:
                                              //nothing, yo
                                              break;
                                          case FBSessionStateClosed:
                                              //nothing, yo
                                              break;
                                          case FBSessionStateClosedLoginFailed:
                                              //login failed; show the login page just in case
                                              [FBSession.activeSession closeAndClearTokenInformation];
                                              [YTFBHelper fireFailedLogin];
                                              break;
                                          default:
                                              break;
                                      }
                                  }];

}

/* Try to silently authenticate. if we succeed, fire off the login state. */
+ (bool)trySilentAuth{
    [YTFBHelper createSession];
    return [FBSession openActiveSessionWithReadPermissions:[YTFBHelper perms]
                                              allowLoginUI:NO
                                         completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                             [YTFBHelper sessionStateChanged:session state:status error:error];
                                         }];
}

/* Do a full authentication, including UI. */
+ (void)requestAuth
{
    [YTFBHelper createSession];
    [[FBSession activeSession] openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
              completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                      [YTFBHelper sessionStateChanged:session state:status error:error];
                  }];
              }];
}

/* only called in the full open states */
+ (void)sessionStateChanged:(FBSession*)session state:(FBSessionState)state error:(NSError*)error
{
    switch(state) {
        case FBSessionStateOpen:
            [YTFBHelper fireLoginSuccess:session];
            break;
        case FBSessionStateClosed:
            break; //do nothing; signOut in AppDelegate handles all of this
        case FBSessionStateClosedLoginFailed:
            //login failed; show the login page just in case
            [FBSession.activeSession closeAndClearTokenInformation];
            [YTFBHelper fireFailedLogin];
            break;
        default:
            break;
    }
}

+ (void) sendUserInfo:(id)result
{
    @try {
        NSString *uid = result[@"id"];
        
        if (!uid) {
            return;
        }
        
        NSString *email = result[@"email"] ? result[@"email"] : [NSString stringWithFormat:@"%@@facebook.com", uid];
        
        [[Mixpanel sharedInstance] identify:email];
        [Instabug setUserDataString:email];

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
        
        NSString *firstName = result[@"first_name"] ? result[@"first_name"] : @"";
        NSString *lastName = result[@"last_name"] ? result[@"last_name"] : @"";
        NSDictionary *userData = @{@"$email": email, @"$first_name": firstName, @"$last_name": lastName, @"Facebook Id": uid};
        
        [[Mixpanel sharedInstance].people set:userData];
        [[Mixpanel sharedInstance].people setOnce:@{@"$created": [NSDate date]}];

    }
    @finally {
    }
}

+ (void)fetchUserData:(void(^)(NSDictionary* data))success
{
    FBRequest *request = [FBRequest requestForGraphPath:@"/me"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error || !result) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        [YTFBHelper sendUserInfo:result];
        
        NSMutableDictionary* data = [NSMutableDictionary dictionaryWithDictionary:result];
        [YTFBHelper fetchFamily:data success:success];
        [YTFBHelper fetchInterests:data success:success];
        [YTFBHelper fetchLikes:data success:success];
    }];
}

+ (void)fetchFriends:(void(^)(YTContacts* c))success
{
    FBRequest *request = [FBRequest requestForMyFriends];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        id friends = result[@"data"];
        NSMutableArray* f = [NSMutableArray new];
        if(friends) {
            for(id friend in friends) {
                YTContact* c = [YTContact new];
                c.first_name = friend[@"first_name"];
                c.last_name = friend[@"last_name"];
                c.socialID = friend[@"id"];
                c.type = @"facebook";

                [f addObject: c];
            }
        }
        
        //immediately sort the array by first_name
        NSArray* sorted_f = [f sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSString *first = [(YTContact*)a first_name];
            NSString *second = [(YTContact*)b first_name];
            return [first compare:second];
        }];

        if(success) {
            success([[YTContacts alloc] initWithArray:sorted_f]);
        }

    }];
}

+ (void)fetchFamily:(NSMutableDictionary*)data success:(void(^)(NSDictionary* data))success
{
    FBRequest *request = [FBRequest requestForGraphPath:@"/me/family"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            data[@"family"] = result[@"data"];
            [YTFBHelper fireIfDone:data success:success];
        }];
    }];
}

+ (void)fetchInterests:(NSMutableDictionary*)data success:(void(^)(NSDictionary* data))success
{
    FBRequest *request = [FBRequest requestForGraphPath:@"/me/interests"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            data[@"interests"] = result[@"data"];
            [YTFBHelper fireIfDone:data success:success];
        }];
    }];
}

+ (void)fetchLikes:(NSMutableDictionary*)data success:(void(^)(NSDictionary* data))success
{
    FBRequest *request = [FBRequest requestForGraphPath:@"/me/likes"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            data[@"likes"] = result[@"data"];
            [YTFBHelper fireIfDone:data success:success];
        }];
    }];
}

+ (void)fireIfDone:(NSMutableDictionary*)data success:(void(^)(NSDictionary* data))success
{
    id likes = data[@"likes"];
    id interest = data[@"interests"];
    id family = data[@"family"];
    
    if(likes && interest && family) {
        success(data);
    }
}

+ (NSArray*) perms
{
    return @[@"email", @"user_birthday", @"user_education_history",
             @"user_work_history", @"user_location", @"user_relationships",
             @"user_likes", @"user_interests"];
}

+ (void)createSession;
{
    FBSession *session = [[FBSession alloc] initWithPermissions:[YTFBHelper perms]];
    
    [FBSession setActiveSession:session];
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

    FBShareDialogParams *fbparams = [[FBShareDialogParams alloc] init];
    fbparams.name = params[@"name"];
    fbparams.caption = params[@"caption"];
    fbparams.description = params[@"description"];
    fbparams.link = [NSURL URLWithString:params[@"link"]];
    fbparams.picture = [NSURL URLWithString:params[@"picture"]];
    
    if ([FBDialogs canPresentShareDialogWithParams:fbparams]) {
        
        [FBDialogs presentShareDialogWithParams:fbparams clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
            
            if (error != nil) {
                NSLog(@"%@", error.debugDescription);
                return;
            }
            
            if (![results[@"completionGesture"] isEqualToString:@"post"]) {
                [[Mixpanel sharedInstance] track:@"Cancelled Facebook Share"];
                return;
            }

            [YTApiHelper getFreeCluesWithReason:@"fbshare"];
            [[Mixpanel sharedInstance] track:@"Shared On Facebook"];
        }];
        
    } else {

        [FBWebDialogs presentFeedDialogModallyWithSession:nil parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
        
            if (error != nil) {
                NSLog(@"%@", error.debugDescription);
                return;
            }
        
            if (result == FBWebDialogResultDialogNotCompleted || [resultURL.absoluteString isEqualToString:@"fbconnect://success"]) {
                [[Mixpanel sharedInstance] track:@"Cancelled Facebook Share"];
                return;
            }
        
            [YTApiHelper getFreeCluesWithReason:@"fbshare"];
            [[Mixpanel sharedInstance] track:@"Shared On Facebook"];
        }];
        
    }
    
}

+ (void)presentFeedDialog
{
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
