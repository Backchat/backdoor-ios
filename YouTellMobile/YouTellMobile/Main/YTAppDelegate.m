//
//  YTAppDelegate.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

#import <FlurrySDK/Flurry.h>
#import <Mixpanel.h>
#import <Instabug/Instabug.h>
#import <iVersion.h>

#import "YTAppDelegate.h"
#import "YTGabViewController.h"
#import "YTModelHelper.h"
#import "YTApiHelper.h"
#import "YTViewHelper.h"
#import "YTFBHelper.h"
#import "YTGPPHelper.h"
#import "YTHelper.h"
#import "YTNotifHelper.h"
#import "YTRateHelper.h"
#import "YTConfig.h"
#import "YTFriendNotifHelper.h"
#import "YTSocialHelper.h"

void uncaughtExceptionHandler(NSException *exception)
{
    [Flurry logError:@"Uncaught exception" message:@"Exception" exception:exception];
    NSLog(@"uncaught");
}

@interface YTAppDelegate ()
@property (nonatomic, retain) NSNumber* launchGabOnLogin;
@end

@implementation YTAppDelegate
- (id) init
{
    if(self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loginSuccess:)
                                                     name:YTLoginSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loginFailure:)
                                                     name:YTLoginFailure
                                                   object:nil];
    }
    return self;
}

# pragma mark Custom methods

+ (YTAppDelegate*)current
{
    return (YTAppDelegate*)[UIApplication sharedApplication].delegate;
}

- (void)loginSuccess:(NSNotification*)note
{
    self.currentUser = note.object;
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge)];
    
    if(self.launchGabOnLogin) {
        [YTViewHelper showGabWithGabId:self.launchGabOnLogin];
        self.launchGabOnLogin = nil;
    }
    else {
        [YTViewHelper hideLogin];
    }
}

- (void)loginFailure:(NSNotification*)note
{
    NSString* message;
    if(note.object == YTLoginFailureServer)
        message = NSLocalizedString(@"Sorry about this. Our servers are overloaded. Please wait a second to try again.", nil);
    else if(note.object == YTLoginFailureReasonSocial)
        message = NSLocalizedString(@"Sorry, your social network didn't authenticate correctly. Please try again", nil);
    else
        message = NSLocalizedString(@"Sorry about this. Please wait a second to try again", nil);
    
    UIAlertView* view = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil)
                                                   message:message
                                                  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [view show];
    
    if(self.currentUser) {
        //we may have tried to login using cached tokens. If so, logout and clear
        //everything to force the user to login again:
        [self.currentUser logout];
    }
    
    [YTViewHelper showLoginWithButtons];
}

+ (void)initialize
{
#ifdef CONFIGURATION_Release
    [iVersion sharedInstance].appStoreID = CONFIG_APPLE_ID_INT;
#else
    [iVersion sharedInstance].checkAtLaunch = NO;
#endif
    [[YTRateHelper sharedInstance] setup];
}

# pragma mark UISplitViewControllerDelegate methods

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;
}

# pragma mark Hockey methods

- (NSString *)customDeviceIdentifierForUpdateManager:(BITUpdateManager *)updateManager
{
//#ifndef CONFIGURATION_RELEASE
//#ifdef TRUE //TODO use production check
//    if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)])
//        return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
//#endif
//#endif
    return nil;
}

#pragma mark UIApplicationDelegate methods
- (void) checkVersion
{
    bool versionDifferent = false;
    NSString* thisVersion = [iVersion sharedInstance].applicationVersion;
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    NSString* YTVERSIONKEY = @"YTVERSIONKEY";
    NSString* lastVersion = [def stringForKey:YTVERSIONKEY];
    versionDifferent = !lastVersion || ![thisVersion isEqualToString:lastVersion];
    
    if(versionDifferent) {
        //new version; destroy ALL THE THINGS
        [YTUser clearCachedTokens];
        [YTModelHelper removeAllStores];
        [[YTRateHelper sharedInstance] reset];
        [[Mixpanel sharedInstance] track:@"Upgraded Application"];
        [def setValue:thisVersion forKey:YTVERSIONKEY];
        [def synchronize];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];        
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    if (CONFIG_DEBUG_FLURRY) {
        [Flurry setDebugLogEnabled:YES];
        [Flurry setEventLoggingEnabled:YES];
    }
    
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:CONFIG_FLURRY_APP_TOKEN];
    
    [Mixpanel sharedInstanceWithToken:CONFIG_MIXPANEL_TOKEN];
    [[Mixpanel sharedInstance] track:@"Launched Application"];
    
    BITHockeyManager *manager = [BITHockeyManager sharedHockeyManager];

    [manager configureWithIdentifier:CONFIG_HOCKEY_ID delegate:self];
    [manager updateManager].delegate = self;
    
    manager.disableUpdateManager = TRUE; //PRODUCTION
    manager.updateManager.checkForUpdateOnLaunch = NO;
    manager.updateManager.updateSetting = BITUpdateCheckManually;
    
    [manager crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;    
    [manager startManager];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    [YTApiHelper setup];
    [YTViewHelper setup];
    [YTUser initalizeSocialHandlers];
    
    [self checkVersion];

    [Instabug KickOffWithToken:CONFIG_INSTABUG_TOKEN CaptureSource:InstabugCaptureSourceUIKit
                 FeedbackEvent:InstabugFeedbackEventShake
            IsTrackingLocation:YES];
    
    //there is no need to play vibration if we do indeed have a gab APN, because
    //iOS vibrates for us.
    NSNumber* gab_id = (NSNumber*)launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey][@"gab_id"];
    self.launchGabOnLogin = gab_id;

    //we have a cached login token?
    if(![YTUser attemptCachedLogin]) {

        //we do not, but we may have been authorized via FB/GPP.
        //throw up the login window but without buttons, so the user
        //sees something:
        [YTViewHelper showLogin];

        if(![YTUser attemptCachedSocialLogin]) {
            [YTViewHelper showLoginWithButtons];
        }
    }
    
    [YTAppDelegate.current.window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[FBSession activeSession] handleDidBecomeActive];
    if(self.currentUser) {
        //if we are logged in, go ahead, show the rate helper:
        [[YTRateHelper sharedInstance] run];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[Mixpanel sharedInstance] track:@"Deactivated Application"];
    [[Mixpanel sharedInstance] flush];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    [[Mixpanel sharedInstance] track:@"Terminated Application"];
    [[Mixpanel sharedInstance] flush];
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[url scheme] rangeOfString:@"fb"].location == 0) {
        return [YTFBHelper handleOpenUrl:url];
    } else {
        return [[YTGPPHelper sharedInstance] handleOpenURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    
    return NO;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    if([YTAppDelegate current].currentUser)
        [YTAppDelegate.current.currentUser setDeviceToken:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if([YTHelper simulatedEnvironment]) {
        return;
    }
    
    static bool alertedThisRun = false;
    
    if(!alertedThisRun) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Push notifications", nil)
                                                        message:NSLocalizedString(@"With push notifications on, Backdoor will alert you when you receive messages and when your friends join Backdoor. Consider turning notifications on by going to\nSettings | Notifications | Backdoor\nand then logging out and in again.", nil)
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
        [alert show];
        alertedThisRun = true;
        [[Mixpanel sharedInstance] track:@"User declined APN"];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if ([userInfo[@"kind"] isEqualToNumber:@1]) {
        if(self.currentUser) {
            [[YTFriendNotifHelper sharedInstance] handleNotification:userInfo];
            return;
        }
    }
    else if([userInfo[@"kind"] isEqualToNumber:@0]) {
        id gab_id = userInfo[@"gab_id"];

        if(self.currentUser) {

            YTGab* gab = [YTGab gabForId:gab_id];
            //we absolutely know we need to update, irregardless of state
            [gab update:YES];
            NSLog(@"updating %@", gab);
            //if we are NOT active, then when we COME IN, iOS vibrates for us:
            if (application.applicationState != UIApplicationStateActive)
            {
                //show the gab view without any annimatino
                [YTViewHelper showGab:gab animated:NO];
            }
            else {
                //make it rain-vibrate i mean.
                [YTNotifHelper handleNotification:userInfo];
                
            }
            
        }
        else {
            self.launchGabOnLogin = gab_id;
        }
    }
    else {
        NSString *message = userInfo[@"aps"][@"alert"];
        if (!message) {
            return;
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
}

#pragma mark - Core Data stack

@end