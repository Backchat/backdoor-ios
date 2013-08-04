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
#import "YTContactHelper.h"
#import "YTHelper.h"
#import "YTSocialHelper.h"

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
}

- (void)signIn
{
    [[GPPSignIn sharedInstance] authenticate];
}

- (void)setup
{
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.clientID = CONFIG_GPP_CLIENT_ID;
    signIn.scopes = @[kGTLAuthScopePlusLogin];
    signIn.delegate = self;
    signIn.shouldFetchGoogleUserEmail = YES;
    
    [[YTSocialHelper sharedInstance] setLoggedIn:@"gpp" loggedIn:signIn.hasAuthInKeychain];
    
    [signIn trySilentAuthentication];
}

# pragma mark GPPSignInDelegate methods

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error
{
    if (error) {
        [[YTSocialHelper sharedInstance] setLoggedIn:@"gpp" loggedIn:NO];
        return;
    }
    
    if (!auth.accessToken || !auth.userEmail) {
        [[YTSocialHelper sharedInstance] setLoggedIn:@"gpp" loggedIn:NO];
        return;
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        [[YTSocialHelper sharedInstance] setLoggedIn:@"gpp" loggedIn:YES];
        
        [YTApiHelper resetUserInfo];
        
        [Flurry logEvent:@"Signed_In_With_Google+"];
        [[Mixpanel sharedInstance] track:@"Signed In With Google+"];

        YTAppDelegate *delegate = [YTAppDelegate current];

        delegate.userInfo[@"provider"] = @"gpp";
        delegate.userInfo[@"access_token"] = auth.accessToken;
        delegate.userInfo[@"gpp_data"][@"email"] = auth.userEmail;
        delegate.userInfo[@"email"] = auth.userEmail;
        [YTApiHelper login:^(id JSON) {
            [self fetchUserData];
        }];
        
        [YTModelHelper changeStoreId:auth.userEmail];
        [YTApiHelper postLogin];
    }];
}

- (void)fetchUserData
{
    GTLServicePlus *service = [GTLServicePlus new];
    service.retryEnabled = YES;
    service.authorizer = [GPPSignIn sharedInstance].authentication;
    
    GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLPlusPerson *person, NSError *error) {
        
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        
        YTAppDelegate *delegate = [YTAppDelegate current];
        NSString *email = delegate.userInfo[@"gpp_data"][@"email"];
        
        [[Mixpanel sharedInstance] identify:email];
        [Instabug setUserDataString:email];

        
        if (delegate.deviceToken) {
            [[Mixpanel sharedInstance].people addPushDeviceToken:delegate.deviceToken];
        }
        
        if ([person.gender isEqualToString:@"male"]) {
            [Flurry setGender:@"m"];
            [[Mixpanel sharedInstance].people set:@"Gender" to:@"Male"];
        } else if ([person.gender isEqualToString:@"female"]) {
            [Flurry setGender:@"f"];
            [[Mixpanel sharedInstance].people set:@"Gender" to:@"Female"];
        }
        
        NSInteger age = [YTHelper ageWithBirthdayString:[person JSON][@"birthday"] format:@"yyyy-MM-dd"];
        
        NSDictionary *userData = @{@"$first_name": person.name.givenName, @"$last_name": person.name.familyName, @"$email": email, @"Age": [NSNumber numberWithInt:age], @"Google+ Id": person.identifier};
        [[Mixpanel sharedInstance].people set:userData];
        [[Mixpanel sharedInstance].people setOnce:@{@"$created": [NSDate date]}];
        
       
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            YTAppDelegate *delegate = [YTAppDelegate current];
            [delegate.userInfo[@"gpp_data"] addEntriesFromDictionary:[person JSON]];
            [YTApiHelper updateUserInfo:nil];
            //not going to do this [self fetchFriendsWithPageToken:nil];
        }];
    }];
}

- (void)fetchFriendsWithPageToken:(NSString*)pageToken
{
    GTLServicePlus *service = [GTLServicePlus new];
    service.retryEnabled = YES;
    service.authorizer = [GPPSignIn sharedInstance].authentication;
    
    GTLQueryPlus *query = [GTLQueryPlus queryForPeopleListWithUserId:@"me" collection:kGTLPlusCollectionVisible];
    query.pageToken = pageToken;
    
    if (!pageToken) {
        self.friends = [NSMutableArray new];
    }
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLPlusPeopleFeed *peopleFeed, NSError *error) {
        if (error) {
            NSLog(@"%@", error.debugDescription);
            return;
        }
        [self.friends addObjectsFromArray:[peopleFeed JSON][@"items"]];

        if (peopleFeed.nextPageToken) {
            [self fetchFriendsWithPageToken:peopleFeed.nextPageToken];
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[YTContactHelper sharedInstance] loadGPPFriends:self.friends];
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
    /*
    if (![[YTAppDelegate current].userInfo[@"provider"] isEqualToString:@"gpp"]) {
        return;
    }
     */
    
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
