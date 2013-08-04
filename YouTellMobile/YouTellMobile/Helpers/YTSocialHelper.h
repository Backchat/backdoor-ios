//
//  YTSocialHelper.h
//  Backdoor
//
//  Created by Łukasz S on 6/5/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface YTSocialHelper : NSObject

@property (assign, nonatomic) BOOL loginViewEnabled;
@property (strong, nonatomic) NSMutableDictionary *loggedIn;

+ (YTSocialHelper*)sharedInstance;
- (void)setup;
- (BOOL)isGPP;
- (BOOL)isFacebook;
- (void)presentShareDialog;

- (void)enableLoginView:(BOOL)enabled;
- (void)setLoggedIn:(NSString*)provider loggedIn:(BOOL)loggedIn;

@end
