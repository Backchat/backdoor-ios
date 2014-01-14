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
@property (nonatomic, retain) GTLPlusPerson* person;
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
    self.person = nil;
}

- (GPPSignIn*) getSignIn
{
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.clientID = CONFIG_GPP_CLIENT_ID;
    signIn.scopes = @[kGTLAuthScopePlusLogin];
    signIn.delegate = self;
    signIn.shouldFetchGoogleUserEmail = YES;
    signIn.shouldFetchGoogleUserID = YES;

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

- (void)sendUserData
{
    @try {
        [[Mixpanel sharedInstance] identify:self.email];
        [Instabug setUserDataString:self.email];
        
        if ([self.person.gender isEqualToString:@"male"]) {
            [Flurry setGender:@"m"];
            [[Mixpanel sharedInstance].people set:@"Gender" to:@"Male"];
        } else if ([self.person.gender isEqualToString:@"female"]) {
            [Flurry setGender:@"f"];
            [[Mixpanel sharedInstance].people set:@"Gender" to:@"Female"];
        }
        
        NSInteger age = [YTHelper ageWithBirthdayString:self.person.birthday format:@"yyyy-MM-dd"];
        
        if (age > 0) {
            [Flurry setAge:age];
            [[Mixpanel sharedInstance].people set:@"Age" to:[NSNumber numberWithInt:age]];
        }
        
        NSString* fname = self.person.name.givenName ? self.person.name.givenName : @"";
        NSString* lname = self.person.name.familyName ? self.person.name.familyName : @"";
        NSDictionary *userData = @{@"$first_name": fname,
                                   @"$last_name": lname,
                                   @"$email": self.email,
                                   @"Google+ Id": self.person.identifier};
        
        [[Mixpanel sharedInstance].people set:userData];
        [[Mixpanel sharedInstance].people setOnce:@{@"$created": [NSDate date]}];
    }
    @finally {
    }
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

    GTLServicePlus *service = [GTLServicePlus new];
    service.retryEnabled = YES;
    service.authorizer = [GPPSignIn sharedInstance].authentication;
    
    GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
    
    self.email = auth.userEmail;
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLPlusPerson *person, NSError *error) {
        
        if (error || !person) {
            NSLog(@"%@", error.debugDescription);
            [self fireFailedLogin];
            return;
        }

        self.person = person;
        
        [Flurry logEvent:@"Signed_In_With_Google+"];
        [[Mixpanel sharedInstance] track:@"Signed In With Google+"];
        
        NSString* fname = self.person.name.givenName ? self.person.name.givenName : @"";
        NSString* lname = self.person.name.familyName ? self.person.name.familyName : @"";
        NSString* fullName = [NSString stringWithFormat:@"%@ %@", fname, lname];
        
        NSDictionary* dict =
        @{YTSocialLoggedInAccessTokenKey: auth.accessToken,
          YTSocialLoggedInProviderKey: [NSNumber numberWithInteger:YTSocialProviderGPP],
          YTSocialLoggedInNameKey: fullName};
        
        if(!reauthenticating) {
            [[NSNotificationCenter defaultCenter] postNotificationName:YTSocialLoggedIn
                                                                object:nil
                                                              userInfo:dict];
        }
        else {
            reauthenticating = false;            
            [[NSNotificationCenter defaultCenter] postNotificationName:YTSocialReauthSuccess
                                                                object:nil
                                                              userInfo:dict];
            
        }
        
    }];
}

- (void)fetchUserData:(void(^)(NSDictionary* data))success;
{
    [self sendUserData];
    
    NSMutableDictionary* data = [NSMutableDictionary new];
    [data addEntriesFromDictionary:[self.person JSON]];
    data[@"email"] = self.email;
    success(data);
}

- (BOOL)handleOpenURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation
{
    return [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)presentShareDialog
{
    [GPPShare sharedInstance].delegate = self;

    id<GPPShareBuilder> builder = [[GPPShare sharedInstance] shareDialog];
    [builder setURLToShare:[NSURL URLWithString:CONFIG_SHARE_URL]];
    [builder setPrefillText:NSLocalizedString(@"Message me anything you want anonymously with Backchat.  Backchat Me!", nil)];
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
