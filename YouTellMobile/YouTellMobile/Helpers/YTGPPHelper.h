//
//  YTGPHelper.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>

@interface YTGPPHelper : NSObject <GPPSignInDelegate, GPPShareDelegate>

+ (YTGPPHelper*)sharedInstance;

- (BOOL)handleOpenURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation;
- (void)signOut;
- (void)signIn;
- (void)setup;
- (void)presentShareDialog;

@property (strong, nonatomic) NSMutableArray *friends;

@end
