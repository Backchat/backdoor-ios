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
#import "YTUser.h"
#import <Reachability.h>

@class YTViewController;
@class YTSheetViewController;

@interface YTAppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate, BITCrashManagerDelegate, BITUpdateManagerDelegate, BITHockeyManagerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UISplitViewController *splitController;
@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) UINavigationController *detailsController;

@property (strong, nonatomic) YTMainViewController *currentMainViewController;
@property (weak, nonatomic) YTGabViewController *currentGabViewController;

@property (assign) BOOL usesSplitView;

@property (strong, nonatomic) YTStoreHelper *storeHelper;

@property (strong, nonatomic) YTUser* currentUser;

@property (strong, nonatomic) Reachability* reachability;

@property (weak, nonatomic) YTSheetViewController* sheetView;

+ (YTAppDelegate*)current;

@end