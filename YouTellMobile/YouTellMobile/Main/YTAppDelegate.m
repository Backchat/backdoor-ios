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
#import <iRate/iRate.h>
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
@end

@implementation YTAppDelegate

# pragma mark Custom methods

+ (YTAppDelegate*)current
{
    return (YTAppDelegate*)[UIApplication sharedApplication].delegate;
}

- (id) init {
    if(self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggedIn:) name:YTLoginSuccess
                                                   object:nil];
    }
    return self;
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

- (void)loggedIn:(NSNotification*)note
{
    [[YTSocialHelper sharedInstance] fetchUserData];
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
        
    [YTApiHelper setup];
    [YTModelHelper setup];    
    [YTViewHelper setup];
    BITHockeyManager *manager = [BITHockeyManager sharedHockeyManager];

    [manager configureWithIdentifier:CONFIG_HOCKEY_ID delegate:self];
    [manager updateManager].delegate = self;
    
    manager.disableUpdateManager = TRUE; //PRODUCTION
    manager.updateManager.checkForUpdateOnLaunch = NO;
    manager.updateManager.updateSetting = BITUpdateCheckManually;
    
    [manager crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;    
    [manager startManager];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    if (CONFIG_DEBUG_FLURRY) {
        [Flurry setDebugLogEnabled:YES];
        [Flurry setEventLoggingEnabled:YES];
    }
    
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:CONFIG_FLURRY_APP_TOKEN];
    
    [Mixpanel sharedInstanceWithToken:CONFIG_MIXPANEL_TOKEN];
    [[Mixpanel sharedInstance] track:@"Launched Application"];

    [Instabug KickOffWithToken:CONFIG_INSTABUG_TOKEN CaptureSource:InstabugCaptureSourceUIKit FeedbackEvent:InstabugFeedbackEventShake IsTrackingLocation:YES];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge)];
    
    if([YTHelper simulatedEnvironment]) {
        [YTAppDelegate current].userInfo[@"device_token"] = @"1"; //not like you can run multiple simulators...
    }
    
    [YTNotifHelper handleNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];

    NSNumber* gab_id = (NSNumber*)launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey][@"gab_id"];

    //we have a cached login token?
    if(![YTApiHelper attemptCachedLogin]) {
        //we do not, but we may have been authorized via FB/GPP.
        //throw up the login window but without buttons, so the user
        //sees something:
        [YTViewHelper showLogin];

        if(gab_id) {//do we need to launch a gab after logging in?
            [YTAppDelegate current].userInfo[@"launch_on_active_token"] = gab_id;
        }

        bool logged_in = [YTFBHelper trySilentAuth];
        if(!logged_in)
            logged_in = [[YTGPPHelper sharedInstance] trySilentAuth];
        
        if(!logged_in)
            [YTViewHelper showLoginWithButtons];
    }
    else {
        if(gab_id) {
            [YTViewHelper showGabWithGabId:gab_id];
        }
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[FBSession activeSession] handleDidBecomeActive];
    [[YTRateHelper sharedInstance] run];
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
    self.userInfo[@"device_token"] = [YTHelper hexStringFromData:deviceToken];
    NSLog(@"device token %@", self.userInfo[@"device_token"]);
    self.deviceToken = deviceToken;
    [[NSNotificationCenter defaultCenter] postNotificationName:YTDeviceTokenAcquired object:nil];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if(![YTHelper simulatedEnvironment]) {
        self.userInfo[@"device_token"] = @"";
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if ([userInfo[@"kind"] isEqualToNumber:@1]) {
        [[YTFriendNotifHelper sharedInstance] handleNotification:userInfo];
        return;
    }
    
    if (!userInfo[@"gab_id"]) {
        NSString *message = userInfo[@"aps"][@"alert"];
        if (!message) {
            return;
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    id gab_id = userInfo[@"gab_id"];

    if([YTApiHelper loggedIn]) {
        [YTNotifHelper handleNotification:userInfo];
        YTGab* gab = [YTGab gabForId:gab_id];
        //we absolutely know we need to update, irregardless of state
        gab.needs_update = @true;
        [gab update];
        NSLog(@"updating %@", gab);
        if (application.applicationState != UIApplicationStateActive) {
            [YTViewHelper showGab:gab];
        }
    }
    else {
        [YTAppDelegate current].userInfo[@"launch_on_active_token"] = gab_id;
    }
}

#pragma mark - Core Data stack

@end

NSString* const YTDeviceTokenAcquired = @"YTDeviceTokenAcquired";
