//
//  YTContactHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTContactHelper : NSObject
+ (void)setup;
+ (void)loadAddressBook;
+ (void)loadFacebookFriends:(NSArray*)friends;
+ (void)loadGPPFriends:(NSArray*)friends;
+ (NSArray*)findContactsWithString:(NSString*)string grouped:(BOOL)grouped;
+ (NSDictionary*)findContactWithType:(NSString*)type value:(NSString*)value;


@end

