//
//  YTSocialHelper.h
//  Backdoor
//
//  Created by Łukasz S on 6/5/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface YTSocialHelper : NSObject

+ (YTSocialHelper*)sharedInstance;
- (BOOL)isGPP;
- (BOOL)isFacebook;
- (void)presentShareDialog;
- (void)fetchUserData;
- (void)reauthProviders;
- (void)logoutProviders;
@end
