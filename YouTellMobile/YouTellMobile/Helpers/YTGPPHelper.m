//
//  YTGPHelper.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>

#import <FlurrySDK/Flurry.h>
#import <Mixpanel.h>
#import <Instabug/Instabug.h>

#import "YTGPPHelper.h"
#import "YTApiHelper.h"
#import "YTConfig.h"
#import "YTViewHelper.h"
#import "YTModelHelper.h"
#import "YTAppDelegate.h"
#import "YTHelper.h"
#import "YTSocialHelper.h"

@interface YTGPPHelper ()
{
    bool reauthenticating;
}
@property (nonatomic, retain) NSString* email;
@end

@implementation YTGPPHelper

+ (YTGPPHelper*)sharedInstance
{
    static YTGPPHelper *instance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        instance = [YTGPPHelper new];
    });
    return instance;
}

- (void)signOut
{
    [[GPPSignIn sharedInstance] signOut];
    self.email = nil;
}

- (GPPSignIn*) getSignIn
{
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.clientID = CONFIG_GPP_CLIENT_ID;
    signIn.scopes = @[kGTLAuthScopePlusLogin];
    signIn.delegate = self;
    signIn.shouldFetchGoogleUserEmail = YES;

    return signIn;
}

- (void)requestAuth
{
    reauthenticating = false;
    [[self getSignIn] authenticate];
}

- (void)reauth
{
    reauthenticating = true;
    [[self getSignIn] trySilentAuthentication];
}

- (bool)trySilentAuth
{
    reauthenticating = false;
    return [[self getSignIn] trySilentAuthentication];
}

# pragma mark GPPSignInDelegate methods
- (void) fireFailedLogin
{
    [[NSNotificationCenter defaultCenter] postNotificationName:YTSocialLoginFailed
                                                        object:nil];
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error
{
    if (error) {
        [self fireFailedLogin];
        return;
    }
    
    if (!auth.accessToken || !auth.userEmail) {
        [self fireFailedLogin];
        return;
    }

    if(reauthenticating) {
        reauthenticating = false;
        return;
    }
    
    [Flurry logEvent:@"Signed_In_With_Google+"];
    [[Mixpanel sharedInstance] track:@"Signed In With Google+"];

    NSDictionary* dict =
    @{YTSocialLoggedInAccessTokenKey: auth.accessToken,
      YTSocialLoggedInProviderKey: [NSNumber numberWithInteger:YTSocialProviderGPP]};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YTSocialLoggedIn
                                                        object:nil
                                                      userInfo:dict];

    self.email = auth.userEmail;
}

- (void)fetchUserData:(void(^)(NSDictionary* data))success;
{
    GTLServicePlus *service = [GTLServicePlus new];
    service.retryEnabled = YES;
    service.authorizer = [GPPSignIn sharedInstance].authentication;
    
    GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLPlusPerson *person, NSError *error) {
        
        if (error || !person) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        NSMutableDictionary* data = [NSMutableDictionary new];
        [data addEntriesFromDictionary:[person JSON]];
        data[@"email"] = self.email;
        success(data);
    }];
}

/* TODO: this is not used yet */
- (void)fetchFriendsWithPageToken:(NSString*)pageToken
{
    GTLServicePlus *service = [GTLServicePlus new];
    service.retryEnabled = YES;
    service.authorizer = [GPPSignIn sharedInstance].authentication;
    
    GTLQueryPlus *query = [GTLQueryPlus queryForPeopleListWithUserId:@"me" collection:kGTLPlusCollectionVisible];
    query.pageToken = pageToken;
    
    if (!pageToken) {
        //self.friends = [NSMutableArray new];
    }
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLPlusPeopleFeed *peopleFeed, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        //[self.friends addObjectsFromArray:[peopleFeed JSON][@"items"]];

        if (peopleFeed.nextPageToken) {
            [self fetchFriendsWithPageToken:peopleFeed.nextPageToken];
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                //[[YTContactHelper sharedInstance] loadGPPFriends:self.friends];
            }];
        }
    }];
}

- (BOOL)handleOpenURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation
{
    return [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)presentShareDialog
{
    [GPPShare sharedInstance].delegate = self;

    id<GPPShareBuilder> builder = [[GPPShare sharedInstance] shareDialog];
    //[builder setTitle:NSLocalizedString(@"Try Backdoor", nil) description:NSLocalizedString(@"Backdoor is fun", nil) thumbnailURL:[NSURL URLWithString:@"http://d17ke1zpt7t3r2.cloudfront.net/assets/logo_header.png"]];
    [builder setURLToShare:[NSURL URLWithString:CONFIG_SHARE_URL]];
    [builder setPrefillText:NSLocalizedString(@"Message me anything you want anonymously with Backdoor.  Backdoor Me!", nil)];
    [builder open];
 
}

- (void)finishedSharing:(BOOL)shared
{
    if (shared) {
        [YTApiHelper getFreeCluesWithReason:@"gppshare"];
        [[Mixpanel sharedInstance] track:@"Shared On Google+"];
    } else {
        [[Mixpanel sharedInstance] track:@"Cancelled Google+ Share"];        
        [[Mixpanel sharedInstance] track:@"Cancelled Inviting Friend"];

    }
}

@end
