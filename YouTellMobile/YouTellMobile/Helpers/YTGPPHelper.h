//
//  YTGPHelper.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GPPSignIn.h>
#import <GPPSignInButton.h>
#import <GPPShare.h>

@interface YTGPPHelper : NSObject <GPPSignInDelegate, GPPShareDelegate>

+ (YTGPPHelper*)sharedInstance;

- (BOOL)handleOpenURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation;
- (void)signOut;
- (void)signIn;
- (void)setup;
- (void)presentShareDialog;

@property (strong, nonatomic) NSMutableArray *friends;

@end
