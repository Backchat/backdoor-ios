//
//  YTModelHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define MESSAGE_STATUS_READY 0
#define MESSAGE_STATUS_DELIVERING 1
#define MESSAGE_STATUS_FAILED 2

@interface YTModelHelper : NSObject

+ (void)setup;
+ (void)save;

+ (NSString*)settingsForKey:(NSString*)key;
+ (void)setSettingsForKey:(NSString*)key value:(id)value;
+ (void)removeSettingsForKey:(NSString*)key;

+ (NSManagedObject *)objectForRow:(NSInteger)row entityName:(NSString*)entityName predicate:(NSPredicate*)predicate sortDescriptor:(NSSortDescriptor*)sortDescriptor;
+ (NSInteger)objectCount:(NSString*)entityName predicate:(NSPredicate*)predicate;

+ (NSManagedObject *)gabForRow:(NSInteger)row filter:(NSString*)filter;
+ (NSInteger)gabCountWithFilter:(NSString*)filter;
+ (NSSet*)gabReceiverNames;
+ (NSManagedObject*)gabForId:(NSNumber*)gabId;
+ (void)clearGab:(NSNumber*)gabId;
+ (NSString*)userNameForGab:(NSManagedObject*)gab;
+ (NSManagedObject*)createOrUpdateGab:(id)data;
+ (NSNumber*)nextFakeGabId;
+ (void)updateUnreadCount;

//+ (NSManagedObject *)messageForRow:(NSInteger)row gabId:(id)gabId;
+ (NSArray*)messagesForGab:(id)gabId;
+ (NSInteger)messageCount:(id)gabId;
+ (UIImage*)imageForMessage:(NSManagedObject*)message;
+ (NSManagedObject*)createMessage:(NSDictionary*)data;
+ (NSManagedObject*)updateMessage:(id)data;
+ (void)failMessage:(NSString*)key;

+ (NSDictionary*)cluesForGab:(NSNumber*)gabId;
+ (NSManagedObject*)createOrUpdateClue:(NSDictionary*)data;
+ (NSInteger)userAvailableClues;
+ (void)setUserAvailableClues:(NSNumber*)value;
+ (BOOL)userHasShared;

+ (void)clearContactsWithType:(NSString*)type;
+ (void)addContactWithData:(NSDictionary*)data;
+ (NSArray*)findContactsWithString:(NSString *)string;
+ (NSManagedObject*)findContactWithType:(NSString *)type value:(NSString*)value;

+ (NSIndexPath*)indexPathForGab:(NSNumber*)gabId filter:(NSString*)filter;

+ (NSURL*)modelURL;
+ (NSURL*)storeURL;
+ (void)changeStoreId:(NSString *)storeId;

+ (NSString*)phoneForUid:(NSString*)uid;
+ (void)setPhoneForUid:(NSString*)uid phone:(NSString*)phone;

@end
