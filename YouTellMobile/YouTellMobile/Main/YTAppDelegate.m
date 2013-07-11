//
//  YTAppDelegate.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

#import <FlurrySDK/Flurry.h>
#import <Mixpanel.h>

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
#import "YTConfig.h"

void uncaughtExceptionHandler(NSException *exception)
{
    [Flurry logError:@"Uncaught exception" message:@"Exception" exception:exception];
    NSLog(@"uncaught");
}

@implementation YTAppDelegate

# pragma mark Custom methods

+ (YTAppDelegate*)current
{
    return (YTAppDelegate*)[UIApplication sharedApplication].delegate;
}

- (void)signOut
{
    [[Mixpanel sharedInstance] track:@"Signed Out"];
    [[YTGPPHelper sharedInstance] signOut];
    [YTFBHelper closeSession];
    [YTModelHelper changeStoreId:nil];
    [[YTContactHelper sharedInstance] clearRandomizedFriendWithType:nil];
    [YTApiHelper resetUserInfo];
    [YTViewHelper showLogin];
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
    
    self.storeHelper = [YTStoreHelper new];
    self.featuredUsers = @[];
    
    [YTApiHelper setup];
    [YTModelHelper setup];    
    [[YTContactHelper sharedInstance] setup];
    [YTViewHelper setup];
    [YTFBHelper setup];
    [[YTGPPHelper sharedInstance] setup];
    [YTViewHelper showLogin];

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
    [Flurry startSession:CONFIG_FLURRY_APP_TOKEN];
    
    [Mixpanel sharedInstanceWithToken:CONFIG_MIXPANEL_TOKEN];
    [[Mixpanel sharedInstance] track:@"Launched Application"];
    

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge)];
    
    self.autoSyncGabId = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey][@"gab_id"];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    static BOOL firstTime = YES;
    
    if (firstTime) {
        firstTime = NO;
    } else {
        [YTContactHelper sharedInstance].updateFriends = YES;
        [YTApiHelper autoSync:NO];
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
    self.userInfo[@"device_token"] = [YTHelper hexStringFromData:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    self.userInfo[@"device_token"] = @"";
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (!userInfo[@"gab_id"]) {
        return;
    }
    
    [YTNotifHelper handleNotification:userInfo];
    
    if (application.applicationState == UIApplicationStateActive) {
        [YTApiHelper autoSync:NO];

    } else {
        self.autoSyncGabId = userInfo[@"gab_id"];
        [YTApiHelper autoSync:YES];
    }

}

#pragma mark - Core Data stack


@end
