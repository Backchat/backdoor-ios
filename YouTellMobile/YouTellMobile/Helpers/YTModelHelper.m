//
//  YTModelHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

#import <Base64/MF_Base64Additions.h>

#import "YTConfig.h"
#import "YTHelper.h"
#import "YTModelHelper.h"
#import "YTViewHelper.h"
#import "YTFBHelper.h"
#import "YTGPPHelper.h"
#import "YTTourViewController.h"

@implementation YTModelHelper


+ (void)setup
{
    NSURL *storeURL = [YTModelHelper storeURL];
    //[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    
    NSError *error = nil;
    
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[YTModelHelper modelURL]];
    
    NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    if (![coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        
        if (![coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    NSManagedObjectContext *context = [NSManagedObjectContext new];
    context.persistentStoreCoordinator = coord;
    
    [YTAppDelegate current].managedObjectContext = context;
}

+ (void)save
{
    NSError *error;
    [[YTAppDelegate current].managedObjectContext save:&error];
}

+ (NSString*)settingsForKey:(NSString*)key
{
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Settings"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(key = %@)", key];
    [request setPredicate:pred];
    
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    
    if ([objects count] == 0) {
        return @"";
    }
    NSManagedObject *obj = objects[0];
    return [obj valueForKey:@"value"];
}

+ (void)setSettingsForKey:(NSString*)key value:(id)value
{
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Settings"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(key = %@)", key];
    [request setPredicate:pred];
    
    NSError *error;
    NSObject *object;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    
    if ([objects count] > 0) {
        object = objects[0];
    } else {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"Settings" inManagedObjectContext:context];
    }
    
    [object setValue:key forKey:@"key"];
    [object setValue:value forKey:@"value"];
}

+ (NSManagedObject*)findOrCreateWithId:(NSString*)oId entityName:(NSString*)entityName context:(NSManagedObjectContext*)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSNumber *myId = [YTHelper parseNumber:oId];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(id = %@)", myId];
    
    [request setPredicate:pred];
    
    NSError *error;
    
    NSArray *objects = [context executeFetchRequest:request error:&error];
    NSManagedObject *object;
    if ([objects count] > 0) {
        object = objects[0];
    } else {
        object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
        [object setValue:myId forKey:@"id"];
    }
    
    return object;
}

+ (void)updateGab:(id)data context:(NSManagedObjectContext*)context
{
    NSManagedObject *gab = [YTModelHelper findOrCreateWithId:data[@"id"] entityName:@"Gabs" context:context];
    [gab setValue:data[@"related_user_name"] forKey:@"related_user_name"];
    [gab setValue:data[@"related_avatar"] forKey:@"related_avatar"];

    [gab setValue:data[@"content_cache"] forKey:@"content_cache"];
    [gab setValue:data[@"content_summary"] forKey:@"content_summary"];

    [gab setValue:[YTHelper parseNumber:data[@"unread_count"]] forKey:@"unread_count"];
    [gab setValue:[YTHelper parseNumber:data[@"total_count"]] forKey:@"total_count"];
    [gab setValue:[YTHelper parseNumber:data[@"clue_count"]] forKey:@"clue_count"];

    [gab setValue:[YTHelper parseBool:data[@"sent"]] forKey:@"sent"];

    [gab setValue:[YTHelper parseDate:data[@"last_date"]] forKey:@"last_date"];
}

+ (void)updateMessage:(id)data context:(NSManagedObjectContext*)context
{
    NSManagedObject *message = [YTModelHelper messageForKey:data[@"key"] context:context];

    [message setValue:[NSNumber numberWithInteger:MESSAGE_STATUS_READY] forKey:@"status"];

    [message setValue:[YTHelper parseNumber:data[@"gab_id"]] forKey:@"gab_id"];
    [message setValue:data[@"content"] forKey:@"content"];
    [message setValue:[YTHelper parseNumber:data[@"kind"]] forKey:@"kind"];
    [message setValue:data[@"secret"] forKey:@"secret"];

    [message setValue:[YTHelper parseBool:data[@"read"]] forKey:@"read"];
    [message setValue:[YTHelper parseBool:data[@"deleted"]] forKey:@"deleted"];
    [message setValue:[YTHelper parseBool:data[@"sent"]] forKey:@"sent"];
    
    [message setValue:[YTHelper parseDate:data[@"created_at"]] forKey:@"created_at"];
}

+ (void)createMessage:(NSDictionary*)data
{
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    NSManagedObject *message = [YTModelHelper messageForKey:data[@"key"] context:context];
    [message setValue:[NSNumber numberWithInteger:MESSAGE_STATUS_DELIVERING] forKey:@"status"];
    
    [message setValue:data[@"gab_id"] forKey:@"gab_id"];
    [message setValue:data[@"content"] forKey:@"content"];
    [message setValue:data[@"kind"] forKey:@"kind"];
    [message setValue:data[@"secret"] forKey:@"secret"];
    
    [message setValue:[NSNumber numberWithBool:YES] forKey:@"read"];
    [message setValue:[NSNumber numberWithBool:NO] forKey:@"deleted"];
    [message setValue:[NSNumber numberWithBool:YES] forKey:@"sent"];
    
    /*
    // FIXME: sanitize utc conversions
    NSDate *date = [NSDate date];
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:date];
    date = [date dateByAddingTimeInterval:-seconds];
    [message setValue:date forKey:@"created_at"];
    */
    
    NSArray *messages = [YTModelHelper messagesForGab:data[@"gab_id"]];
    NSManagedObject *lastMessage = [messages lastObject];
    NSDate *date = [lastMessage valueForKey:@"created_at"];
    date = [date dateByAddingTimeInterval:5];
    [message setValue:date forKey:@"created_at"];
}

+ (void)failMessage:(NSString*)key
{
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    NSManagedObject *message = [YTModelHelper messageForKey:key context:context];
    [message setValue:[NSNumber numberWithInteger:MESSAGE_STATUS_DELIVERING] forKey:@"status"];
}

+ (void)updateClue:(id)data context:(NSManagedObjectContext*)context
{
    NSManagedObject *clue = [YTModelHelper findOrCreateWithId:data[@"id"] entityName:@"Clues" context:context];
    
    [clue setValue:[YTHelper parseNumber:data[@"gab_id"]] forKey:@"gab_id"];
    [clue setValue:data[@"field"] forKey:@"field"];
    [clue setValue:data[@"value"] forKey:@"value"];
    [clue setValue:[YTHelper parseNumber:data[@"number"]] forKey:@"number"];

}

+ (NSManagedObject *)objectForRow:(NSInteger)row entityName:(NSString*)entityName predicate:(NSPredicate*)predicate sortDescriptor:(NSSortDescriptor *)sortDescriptor
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    if (sortDescriptor != nil) {
        request.sortDescriptors = @[sortDescriptor];
    }
    request.predicate = predicate;
    request.fetchLimit = 1;
    request.fetchOffset = row;
    
    NSError *error;
 
    NSArray *objects = [context executeFetchRequest:request error:&error];
    
    if ([objects count] == 0) {
        return nil;
    }
    
    return objects[0];
}

+ (NSInteger)objectCount:(NSString*)entityName predicate:(NSPredicate*)predicate
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    request.includesSubentities = NO;
    request.predicate = predicate;
    NSError *error;
    NSInteger count = [context countForFetchRequest:request error:&error];
    
    return count;
}

+ (NSString *)gabFilterFromString:(NSString*)string
{
    if (string == nil || [string isEqualToString:@""]) {
        return @"*";
    }
    
    return [NSString stringWithFormat:@"*%@*", string];
}

+ (NSManagedObject *)gabForRow:(NSInteger)row  filter:(NSString*)filter;
{
    filter = [YTModelHelper gabFilterFromString:filter];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(total_count > 0) && (content_cache LIKE[cd] %@ || related_user_name LIKE[cd] %@)", filter, filter];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"last_date" ascending:NO];
    return [YTModelHelper objectForRow:row entityName:@"Gabs" predicate:pred sortDescriptor:sortDescriptor];
}

+ (NSInteger)gabCountWithFilter:(NSString*)filter;
{
    filter = [YTModelHelper gabFilterFromString:filter];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(total_count > 0) && (content_cache LIKE[cd] %@ || related_user_name LIKE[cd] %@)", filter, filter];
    return [YTModelHelper objectCount:@"Gabs" predicate:pred];
}

+ (void)clearGab:(NSNumber*)gabId
{
    NSManagedObject *gab = [YTModelHelper gabForId:gabId];
    [gab setValue:@0 forKey:@"total_count"];
}

+ (NSManagedObject*)gabForId:(NSNumber*)gabId 
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(id = %@)", gabId];
    
    return [YTModelHelper objectForRow:0 entityName:@"Gabs" predicate:pred sortDescriptor:nil];
}

+ (NSString*)userNameForGab:(NSManagedObject*)gab
{
    NSString *ret = [gab valueForKey:@"related_user_name"];
    if (!ret || [ret length] == 0) {
        ret = NSLocalizedString(@"???", nil);
    }
    return ret;
}

+ (NSIndexPath*)indexPathForGab:(NSNumber*)gabId filter:(NSString*)filter;
{
    filter = [YTModelHelper gabFilterFromString:filter];

    NSManagedObject *gab = [YTModelHelper gabForId:gabId];
    if (!gab) {
        return nil;
    }
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(total_count > 0) && (last_date > %@) && (content_cache LIKE[cd] %@ || related_user_name LIKE[cd] %@)", [gab valueForKey:@"last_date"], filter, filter];
    NSInteger row = [YTModelHelper objectCount:@"Gabs" predicate:pred];
    return [NSIndexPath indexPathForRow:row inSection:0];
}

/*
+ (NSManagedObject *)messageForRow:(NSInteger)row gabId:(id)gabId
{
    NSPredicate *pred = 
    NSSortDescriptor *sortDescriptor = 
    return [YTModelHelper objectForRow:row entityName:@"Messages" predicate:pred sortDescriptor:sortDescriptor];
}
 */

+ (NSArray*)messagesForGab:(id)gabId
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Messages"];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"created_at" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"(gab_id = %@ && deleted = false)", gabId];

    NSError *error;
    
    NSArray *objects = [context executeFetchRequest:request error:&error];
    
    if ([objects count] == 0) {
        return nil;
    }
    
    return objects;
}


+ (NSManagedObject*)messageForKey:(NSString*)key context:(NSManagedObjectContext*)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Messages"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(key = %@)", key];
    
    [request setPredicate:pred];
    
    NSError *error;
    
    NSArray *objects = [context executeFetchRequest:request error:&error];
    NSManagedObject *object;
    if ([objects count] > 0) {
        object = objects[0];
    } else {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"Messages" inManagedObjectContext:context];
        [object setValue:key forKey:@"key"];
    }
    
    return object;
}

+ (NSInteger)messageCount:(id)gabId;
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(gab_id = %@ && deleted = false)", gabId];
    NSInteger ret = [YTModelHelper objectCount:@"Messages" predicate:pred];
    return ret;
}

+ (UIImage*)imageForMessage:(NSManagedObject*)message
{
    NSString *base64 = [message valueForKey:@"content"];
    NSData *data = [NSData dataWithBase64String:base64];
    UIImage *image = [UIImage imageWithData:data];
    return image;    
}

+ (NSDictionary*)cluesForGab:(NSNumber*)gabId
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(gab_id = %@)", gabId];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Clues"];

    request.sortDescriptors = @[sortDescriptor];
    request.predicate = predicate;
    
    NSError *error;
    
    NSArray *objects = [context executeFetchRequest:request error:&error];
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
    
    for (NSManagedObject *obj in objects) {
        NSDictionary *dict = [obj dictionaryWithValuesForKeys:obj.entity.attributesByName.allKeys];
        ret[dict[@"number"]] = dict;
    }
    
    return ret;
}

+ (void)clearDataWithEntityName:(NSString*)entityName
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSManagedObjectContext *context = delegate.managedObjectContext;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.includesPropertyValues = NO;
    
    NSError *error = nil;
    
    for (NSManagedObject *obj in [context executeFetchRequest:fetchRequest error:&error]) {
        [context deleteObject:obj];
    }
}

+ (void)clearData
{
    NSArray *names = @[@"Clues", @"Gabs", @"Messages", @"Settings"];
    for (NSString *name in names) {
        [YTModelHelper clearDataWithEntityName:name];
    }
}

+ (void)loadSyncData:(id)data
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSManagedObjectContext *context = delegate.managedObjectContext;
    
    NSString *oldDbTimestamp = [YTModelHelper settingsForKey:@"db_timestamp"];
    NSString *newDbTimestamp = data[@"db_timestamp"];
    if (![oldDbTimestamp isEqualToString:newDbTimestamp]) {
        [YTModelHelper clearData];
        NSLog(@"clearing data");
    }

    NSString *prevSyncTimeStr = [YTModelHelper settingsForKey:@"sync_time"];
    if (![prevSyncTimeStr isEqualToString:@""]) {
        NSDate *prevSyncTime = [YTHelper parseDate:prevSyncTimeStr];
        NSDate *curSyncTime = [YTHelper parseDate:data[@"sync_time"]];

        if ([curSyncTime timeIntervalSinceDate:prevSyncTime] < 0) {
            return;
        }

    }

    for (id item in data[@"gabs"]) {
        [YTModelHelper updateGab:item context:context];
    }
    
    for (id item in data[@"messages"]) {
        [YTModelHelper updateMessage:item context:context];
    }
    
    for (id item in data[@"clues"]) {
        [YTModelHelper updateClue:item context:context];
    }

    [YTModelHelper setSettingsForKey:@"sync_time" value:data[@"sync_time"]];
    [YTModelHelper setSettingsForKey:@"sync_uid" value:data[@"sync_uid"]];
    [YTModelHelper setSettingsForKey:@"db_timestamp" value:data[@"db_timestamp"]];
    [YTModelHelper setSettingsForKey:@"available_clues" value:data[@"available_clues"]];
    
    NSMutableDictionary *settings = delegate.userInfo[@"settings"];
    [settings setValuesForKeysWithDictionary:data[@"settings"]];

    NSError *error;
    [context save:&error];

    if (CONFIG_DEBUG_TOUR || ![data[@"new_user"] isEqualToNumber:@0]) {
        [YTTourViewController show];
        /*
        [UIView animateWithDuration:0.0f delay:2.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{} completion:^(BOOL finished) {
            [YTFBHelper presentFeedDialog];
            [[YTGPPHelper sharedInstance] presentShareDialog];
        }];
         */
    }
    
    NSInteger unread = [data[@"unread_messages"] integerValue];
    [UIApplication sharedApplication].applicationIconBadgeNumber = unread;
}

+ (NSURL*)modelURL
{
    return [[NSBundle mainBundle] URLForResource:CONFIG_MODEL withExtension:@"momd"];
}

+ (NSURL*)storeURL
{
    NSString *prefix = CONFIG_MODEL;
    NSString *ext = @"sqlite";
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *storeId = [defs stringForKey:@"storeId"];
    NSString *md5 = [YTHelper md5FromString:storeId];
    NSString *filename = [NSString stringWithFormat:@"%@_%@.%@", prefix, md5, ext];
    NSURL *dir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *ret = [dir URLByAppendingPathComponent:filename];
    
    return ret;
}

+ (void)changeStoreId:(NSString *)storeId
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:storeId forKey:@"storeId"];
    [defs synchronize];
    [YTModelHelper setup];
    [YTViewHelper refreshViews];
}

+ (NSInteger)userAvailableClues
{
    NSString *value = [YTModelHelper settingsForKey:@"available_clues"];
    return [value integerValue];
}

+ (void)clearContactsWithType:(NSString *)type
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Contacts"];
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    
    for (NSManagedObject *object in objects) {
        if (type == nil || [type isEqualToString:[object valueForKey:@"type"]]) {
            [context deleteObject:object];
        }
    }
    
    [context save:&error];
}

+ (void)addContactWithData:(NSDictionary *)data
{
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    NSObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Contacts" inManagedObjectContext:context];

    for (NSString *key in [data allKeys]) {
        [object setValue:data[key] forKey:key];
    }    
}

+ (NSArray*)findContactsWithString:(NSString *)string
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Contacts"];
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    
    if (string && ![string isEqualToString:@""]) {
        request.predicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@)", string];
    }
    
    NSSortDescriptor *lastNameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"last_name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    request.sortDescriptors = @[lastNameSortDescriptor, nameSortDescriptor];
    
    NSError *error;
    return [context executeFetchRequest:request error:&error];
}

+ (NSManagedObject*)findContactWithType:(NSString *)type value:(NSString*)value;
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Contacts"];
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    request.predicate = [NSPredicate predicateWithFormat:@"(type = %@ AND value = %@)", type, value];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    return objects[0];
}

+ (NSString*)phoneForUid:(NSString*)uid
{
    NSString *key = [NSString stringWithFormat:@"facebook_%@", uid];
    return [YTModelHelper settingsForKey:key];
}

+ (void)setPhoneForUid:(NSString*)uid phone:(NSString*)phone
{
    NSString *key = [NSString stringWithFormat:@"facebook_%@", uid];
    return [YTModelHelper setSettingsForKey:key value:phone];
}

@end
