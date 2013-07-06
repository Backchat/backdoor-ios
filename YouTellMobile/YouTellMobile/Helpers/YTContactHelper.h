//
//  YTContactHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTContactHelper : NSObject

@property (strong, nonatomic) NSMutableArray *randomizedFriends;
@property (strong, nonatomic) NSArray *filteredRandomizedFriends;


+ (YTContactHelper*)sharedInstance;
- (void)setup;
- (void)loadAddressBook;
- (void)addRandomizedFriends:(NSArray*)friends;
- (void)filterRandomizedFriends;
- (void)loadFacebookFriends:(NSArray*)friends;
- (void)loadGPPFriends:(NSArray*)friends;
- (NSArray*)findContactsFlat;
- (NSArray*)findContactsWithString:(NSString*)string grouped:(BOOL)grouped;
- (NSDictionary*)findContactWithType:(NSString*)type value:(NSString*)value;
- (void)showAvatarInImageView:(UIImageView *)imageView forContact:(NSDictionary*)contact;

@end

