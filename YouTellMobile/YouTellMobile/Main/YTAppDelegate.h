//
//  YTAppDelegate.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <HockeySDK/HockeySDK.h>

#import "YTMainViewController.h"
#import "YTGabViewController.h"
#import "YTStoreHelper.h"

@class YTViewController;

@interface YTAppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate, BITCrashManagerDelegate, BITUpdateManagerDelegate, BITHockeyManagerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UISplitViewController *splitController;
@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) UINavigationController *detailsController;

@property (weak, nonatomic) YTMainViewController *currentMainViewController;
@property (weak, nonatomic) YTGabViewController *currentGabViewController;

@property (assign) BOOL usesSplitView;
@property (strong, nonatomic) NSData *deviceToken;

@property (strong, nonatomic) NSMutableDictionary *userInfo;
@property (strong, nonatomic) NSMutableDictionary *sentInfo;
@property (strong, nonatomic) NSMutableDictionary *deliveredMessages;


@property (strong, nonatomic) YTStoreHelper *storeHelper;

+ (YTAppDelegate*)current;

@end

extern NSString* const YTDeviceTokenAcquired;
