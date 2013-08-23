//
//  YTModelHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "YTUser.h"

#define MESSAGE_STATUS_READY 0
#define MESSAGE_STATUS_DELIVERING 1
#define MESSAGE_STATUS_FAILED 2

@interface YTModelHelper : NSObject

+ (void)createContextForUser: (YTUser*)user;
+ (void)save;

+ (NSString*)settingsForKey:(NSString*)key;
+ (void)setSettingsForKey:(NSString*)key value:(id)value;
+ (void)removeSettingsForKey:(NSString*)key;

+ (void)updateUnreadCount;

+ (NSDictionary*)cluesForGab:(NSNumber*)gabId;
+ (NSManagedObject*)createOrUpdateClue:(NSDictionary*)data;
+ (NSInteger)userAvailableClues;
+ (void)setUserAvailableClues:(NSNumber*)value;


+ (NSString*)phoneForUid:(NSString*)uid;
+ (void)setPhoneForUid:(NSString*)uid phone:(NSString*)phone;

@end
