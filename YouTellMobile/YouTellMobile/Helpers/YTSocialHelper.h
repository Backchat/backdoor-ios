//
//  YTSocialHelper.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface YTSocialHelper : NSObject

+ (YTSocialHelper*)sharedInstance;
- (BOOL)isGPP;
- (BOOL)isFacebook;
- (void)presentShareDialog;

@end
