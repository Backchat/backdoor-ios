//
//  YTAppDelegate.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

#import <FlurrySDK/Flurry.h>

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

//util to see if we are being debugged
//from http://developer.apple.com/library/mac/#qa/qa1361/_index.html
#ifdef DEBUG
#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>

static bool isBeingDebugged(void)
// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
{
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    
    // We're being debugged if the P_TRACED flag is set.
    
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}
#endif

@implementation YTAppDelegate

# pragma mark Custom methods

+ (YTAppDelegate*)current
{
    return (YTAppDelegate*)[UIApplication sharedApplication].delegate;
}

- (void)signOut
{
    [[YTGPPHelper sharedInstance] signOut];
    [YTFBHelper closeSession];
    [YTModelHelper changeStoreId:nil];
    [YTAppDelegate current].randFriends = @[];
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
    if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)])
        return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
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
    [YTContactHelper setup];
    [YTViewHelper setup];
    [YTFBHelper setup];
    [[YTGPPHelper sharedInstance] setup];
    [YTViewHelper showLogin];

    BITHockeyManager *manager = [BITHockeyManager sharedHockeyManager];
    [manager configureWithIdentifier:CONFIG_HOCKEY_ID delegate:self];
    [manager updateManager].delegate = self;
#ifdef DEBUG
    if(isBeingDebugged()) {
        [manager updateManager].checkForUpdateOnLaunch = NO;
    }
#endif
    [manager crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
    [manager startManager];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    if (CONFIG_DEBUG_FLURRY) {
        [Flurry setDebugLogEnabled:YES];
        [Flurry setEventLoggingEnabled:YES];
    }
    [Flurry startSession:CONFIG_FLURRY_APP_TOKEN];

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
        [YTApiHelper autoSync:NO];
    }
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
