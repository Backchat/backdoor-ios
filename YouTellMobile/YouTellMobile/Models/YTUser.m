//
//  YTUser.m
//  Backdoor
//
//  Created by Lin Xu on 8/22/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTUser.h"
#import "YTSocialHelper.h"
#import "YTFBHelper.h"
#import "YTGPPHelper.h"
#import "YTApiHelper.h"
#import "YTHelper.h"
#import "YTModelHelper.h"
#import <Mixpanel.h>

@interface YTUser ()
@property (nonatomic, retain) NSString* accessToken;
@property (nonatomic, retain) NSDictionary* socialData;
@property (nonatomic, assign) int availableClues;
@property (nonatomic, assign) int id;
@property (nonatomic, assign) bool isCachedLogin;

- (void)login;
- (void)fireLoginSuccess;
- (void)parseUserSettings:(id)JSON;
@end

NSString* const LOGGED_IN_ACCESS_TOKEN = @"LOGGED_IN_ACCESS_TOKEN";
NSString* const LOGGED_IN_SOCIAL_PROVIDER = @"LOGGED_IN_SOCIAL_PROVIDER";
NSString* const LOGGED_IN_BD_ID  = @"LOGGED_IN_BD_ID";
NSString* const LOGGED_IN_NAME = @"LOGGED_IN_NAME";

@implementation YTUser
- (void)setDeviceToken:(NSData *)deviceToken
{    
    NSString* deviceTokenAsString = [YTHelper hexStringFromData:deviceToken];
    NSDictionary* params = @{@"device_token": deviceTokenAsString};

    [[Mixpanel sharedInstance].people addPushDeviceToken:deviceToken];

    [YTApiHelper sendJSONRequestToPath:@"/devices"
                                method:@"POST" params:params
                               success:^(id JSON) {
                               }
                               failure:^(id JSON) {
                               }
     ];
}

- (void)login
{
    /* we basically let everyone else execute for a second, specifically 
     didFinishLaunching... is finished so we can throw up UI. */
    [self performSelector:@selector(loginWithBlockingUI)
               withObject:nil afterDelay:0];
}

- (void) loginWithBlockingUI
{
    NSString* providerAsString;
    
    if(self.socialProvider == YTSocialProviderFacebook)
        providerAsString = @"facebook";
    else
        providerAsString = @"gpp";
    
    NSDictionary* params = @{@"provider": providerAsString,
                             @"access_token": self.accessToken,
                             };
    
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Logging in", nil)
                                                 path:@"/login"
                                               method:@"POST" params:params
                                              success:^(id JSON) {
                                                  if(!JSON[@"user"] || !JSON[@"user"][@"id"]) {
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:YTLoginFailure object:self];
                                                      return;
                                                  }
                                                  
                                                  self.id = [JSON[@"user"][@"id"] integerValue];
                                                  self.isCachedLogin = false;
                                                  
                                                  [self parseUserSettings:JSON[@"user"][@"settings"]];
                                                  
                                                  NSNumber* num = JSON[@"user"][@"new_user"];
                                                  if(num)
                                                      self.newUser = (num.integerValue == 1);
                                                  
                                                  num = JSON[@"user"][@"available_clues"];
                                                  if(num) {
                                                      self.availableClues = num.integerValue;
                                                      [YTModelHelper setUserAvailableClues:[NSNumber numberWithInt:self.availableClues]];
                                                  }
                                                  
                                                  [self fireLoginSuccess];
                                              }
                                              failure:^(id JSON) {
                                                  //login failed
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:YTLoginFailure
                                                                                                      object:YTLoginFailureServer];
                                              }
     ];
    
}

+ (void) clearCachedTokens
{
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def removeObjectForKey:LOGGED_IN_ACCESS_TOKEN];
    [def removeObjectForKey:LOGGED_IN_SOCIAL_PROVIDER];
    [def removeObjectForKey:LOGGED_IN_BD_ID];
    [def removeObjectForKey:LOGGED_IN_NAME];
    [def synchronize];
}

- (void)logout
{
    [YTUser clearCachedTokens];
    
    [[YTSocialHelper sharedInstance] logoutProviders];

    [[YTAppDelegate current].storeHelper disable];
    [YTAppDelegate current].storeHelper = nil;

    [YTModelHelper save];
    YTAppDelegate.current.managedObjectContext = nil;
    
    NSLog(@"Logging out");
    YTAppDelegate.current.currentUser = nil;
}

- (void) postSettings
{
    //TODO make this actually post all the settings to a different endpoint
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"value":[NSNumber numberWithBool:self.messagesHavePreviews]} options:0 error:&error];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [YTApiHelper sendJSONRequestToPath:@"/update-settings"
                                method:@"POST"
                                params:@{@"key":@"message_preview",@"value":json}
                               success:nil
                               failure:nil];
}

- (void) post
{
    NSString *socialKey;
    NSData *data;

    if(self.socialProvider == YTSocialProviderFacebook) {
        socialKey = @"fb_data";
    }
    else {
        socialKey = @"gpp_data";
    }

    data = [NSJSONSerialization dataWithJSONObject:self.socialData options:NSJSONWritingPrettyPrinted error:nil];

    NSDictionary* params = @{socialKey: [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]};
    [YTApiHelper sendJSONRequestToPath:@"/"
                                method:@"POST" params:params
                               success:nil
                               failure:nil];
}

+ (bool) attemptCachedLogin
{
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    NSString* local_access_token = [def stringForKey:LOGGED_IN_ACCESS_TOKEN];
    
    if(local_access_token && local_access_token.length > 0)
    {
        YTUser* user = [[YTUser alloc] init];
        user.accessToken = local_access_token;
        /* we do, but we still need to reauth our social media. */
        user.socialProvider = [def integerForKey:LOGGED_IN_SOCIAL_PROVIDER];
        if(user.socialProvider == YTSocialProviderFacebook)
            [YTFBHelper reauth];
        else
            [[YTGPPHelper sharedInstance] reauth];

        user.id = [def integerForKey:LOGGED_IN_BD_ID];
        user.name = [def stringForKey:LOGGED_IN_NAME];
        user.isCachedLogin = true;
        [user fireLoginSuccess];
        
        return true;
    }
    else
        return false;
}
         
+ (bool) attemptCachedSocialLogin
{
    //essentially, try FB first always.
    return [YTFBHelper trySilentAuth] || [[YTGPPHelper sharedInstance] trySilentAuth];
}

+ (void) initalizeSocialHandlers
{
    [[NSNotificationCenter defaultCenter] addObserverForName:YTSocialLoggedIn
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      YTUser* newUser = [[YTUser alloc] init];
                                                      newUser.accessToken = [note.userInfo valueForKey:YTSocialLoggedInAccessTokenKey];
                                                      newUser.socialProvider = [[note.userInfo valueForKey:YTSocialLoggedInProviderKey] integerValue];
                                                      newUser.name = [note.userInfo valueForKey:YTSocialLoggedInNameKey];
                                                      [newUser login];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:YTSocialLoginFailed
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      //if tehre are any defaults, clear them
                                                      [YTUser clearCachedTokens];
                                                      //tell the world login failed
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:YTLoginFailure object:YTLoginFailureReasonSocial];
                                                  }];
}

- (void)fireLoginSuccess
{
    /* fireloginsuccess is called when we succesfully authenticate and have an accessToken
     AND a social provider. */
    /* save our info for later. */
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setValue:self.accessToken forKey:LOGGED_IN_ACCESS_TOKEN];
    [def setInteger:self.socialProvider forKey:LOGGED_IN_SOCIAL_PROVIDER];
    [def setInteger:self.id forKey:LOGGED_IN_BD_ID];
    [def setValue:self.name forKey:LOGGED_IN_NAME];
    [def synchronize];
    
    /* setup the store */
    [YTModelHelper createContextForUser:self];
    
    /* immediately try to get our social info and post it. */
    [[YTSocialHelper sharedInstance] fetchUserData:^(NSDictionary* socialData) {
        self.socialData = socialData;
        [self post];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YTLoginSuccess object:self];
}

- (void)parseUserSettings:(id)JSON
{
    if(JSON[@"message_preview"])
        self.messagesHavePreviews = [JSON[@"message_preview"] boolValue];
    if(JSON[@"has_shared"])
        self.userHasShared = [JSON[@"has_shared"] boolValue];
}

- (void)setUnreadCount:(int)new_unread
{
    _unreadCount = new_unread;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:new_unread];
}

@end

NSString* const YTLoginSuccess = @"YTLoginSuccess";
NSString* const YTLoginFailure = @"YTLoginFailure";
NSString* const YTLoginFailureReasonSocial = @"YTLoginFailureReasonSocial";
NSString* const YTLoginFailureServer = @"YTLoginFailureServer";

