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
#import <iRate.h>
#import <iVersion/iVersion.h>

#import "YTAppDelegate.h"
#import "YTGabViewController.h"
#import "YTModelHelper.h"
#import "YTApiHelper.h"
#import "YTViewHelper.h"
#import "YTFBHelper.h"
#import "YTGPPHelper.h"
#import "YTContactHelper.h"
#import "YTHelper.h"
#import "YTNotifHelper.h"
#import "YTRateHelper.h"
#import "YTConfig.h"

void uncaughtExceptionHandler(NSException *exception)
{
    [Flurry logError:@"Uncaught exception" message:@"Exception" exception:exception];
    NSLog(@"uncaught");
}

@interface YTAppDelegate ()
- (void)syncBasedOnView;
@end

@implementation YTAppDelegate

# pragma mark Custom methods

+ (YTAppDelegate*)current
{
    return (YTAppDelegate*)[UIApplication sharedApplication].delegate;
}

+ (void)initialize
{
#ifdef CONFIGURATION_Release
    NSLog(@"icheck");
    [iVersion sharedInstance].appStoreID = CONFIG_APPLE_ID_INT;
#else
    [iVersion sharedInstance].checkAtLaunch = NO;
#endif
    [[YTRateHelper sharedInstance] setup];
}

- (void)signOut
{
    [YTModelHelper removeSettingsForKey:@"logged_in_acccess_token"];
    
    //TODO better?
    [[YTAppDelegate current].storeHelper disable];
    [YTAppDelegate current].storeHelper = nil;
    
    [[Mixpanel sharedInstance] track:@"Signed Out"];
    
    [[YTGPPHelper sharedInstance] signOut];
    [YTFBHelper closeSession];
    
    [YTModelHelper changeStoreId:nil];
    [[YTContactHelper sharedInstance] clearRandomizedFriendWithType:nil];
    
    [YTApiHelper resetUserInfo];
    
    [YTViewHelper showLoginWithButtons];
    [YTViewHelper refreshViews];
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
    
    self.featuredUsers = @[];
    
    [YTApiHelper setup];
    [YTModelHelper setup];    
    [[YTContactHelper sharedInstance] setup];
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
    [Instabug setButtonsColor:[UIColor colorWithRed:(26/255.0) green:(199/255.0) blue:(26/255.0) alpha:1.0]];
    [Instabug setButtonsFontColor:[UIColor colorWithRed:(255/255.0) green:(255/255.0) blue:(255/255.0) alpha:1.0]];
    [Instabug setHeaderColor:[UIColor colorWithRed:(16/255.0) green:(181/255.0) blue:(16/255.0) alpha:1.0]];
    [Instabug setHeaderFontColor:[UIColor colorWithRed:(255/255.0) green:(255/255.0) blue:(255/255.0) alpha:1.0]];
    [Instabug setTextBackgroundColor:[UIColor colorWithRed:(249/255.0) green:(249/255.0) blue:(249/255.0) alpha:1.0]];
    [Instabug setTextFontColor:[UIColor colorWithRed:(82/255.0) green:(83/255.0) blue:(83/255.0) alpha:1.0]];

    
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
            [YTApiHelper syncGabWithId:gab_id];
            [YTViewHelper showGabWithId:gab_id];
        }
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    static BOOL firstTime = YES;
    
    if (firstTime) {
        firstTime = NO;
    } else {
        [self syncBasedOnView];
    }
    
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
    self.deviceToken = deviceToken;
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if(![YTHelper simulatedEnvironment]) {
        self.userInfo[@"device_token"] = @"";
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
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
        [YTApiHelper syncGabWithId:gab_id];
        
        if (application.applicationState != UIApplicationStateActive) {
            if ([YTModelHelper gabForId:gab_id]) {
                [YTViewHelper showGabWithId:gab_id];
            }
        }
    }
    else {
        [YTAppDelegate current].userInfo[@"launch_on_active_token"] = gab_id;
    }
}

- (void) syncBasedOnView
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSNumber* gab_id = nil;
    
    if (delegate.currentMainViewController && delegate.currentMainViewController.selectedGabId) {
        gab_id = delegate.currentMainViewController.selectedGabId;
    }
    
    if (delegate.currentGabViewController && delegate.currentGabViewController.gab) {
        gab_id = [delegate.currentGabViewController.gab valueForKey:@"id"];
    }
    
    if(gab_id) {
        [YTApiHelper syncGabWithId:gab_id];
    }

}

#pragma mark - Core Data stack


@end
