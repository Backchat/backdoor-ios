//
//  YTUser.h
//  Backdoor
//
//  Created by Lin Xu on 8/22/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

enum {
    YTSocialProviderFacebook,
    YTSocialProviderGPP
};

@interface YTUser : NSObject

- (void) logout;
- (void) setDeviceToken:(NSData*)deviceToken;

- (void) post;
- (void) postSettings;

@property (nonatomic, assign) bool newUser;
@property (nonatomic, retain, readonly) NSString* accessToken;

@property (nonatomic, assign) bool userHasShared;
@property (nonatomic, assign) bool messagesHavePreviews;

@property (nonatomic, assign) int socialProvider;

@property (nonatomic, assign, readonly) int availableClues;
@property (nonatomic, assign, readonly) int id;
@property (nonatomic, assign, readonly) bool isCachedLogin;

+ (void) initalizeSocialHandlers;
+ (bool) attemptCachedLogin;
+ (bool) attemptCachedSocialLogin;
+ (void) clearCachedTokens;

@end

extern NSString* const YTLoginSuccess;
extern NSString* const YTLoginFailure;
extern NSString* const YTLoginFailureReasonSocial;
extern NSString* const YTLoginFailureServer;
