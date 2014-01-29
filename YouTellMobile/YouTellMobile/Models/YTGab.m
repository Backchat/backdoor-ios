//
//  YTGab.m
//  Backdoor
//
//  Created by Lin Xu on 8/19/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTGab.h"
#import "YTApiHelper.h"
#import "YTModelHelper.h"
#import "YTAppDelegate.h"
#import "YTHelper.h"
#import <Flurry.h>
#import <Mixpanel.h>
#import "YTGabMessageDeliveryOperation.h"
#import "YTGabPostOperation.h"

@interface YTGab ()
@property (nonatomic, retain) NSString* related_user_name;
@property (nonatomic, retain) NSNumber* clue_count;
@property (nonatomic, retain) NSString* content_cache;
@property (nonatomic, retain) NSArray* messages;
- (void) postMessage:(YTGabMessage*)message;
@end

@implementation YTGab
@dynamic updated_at;
@dynamic content_summary;
@dynamic needs_update;
@dynamic related_user_name;
@dynamic related_avatar;
@dynamic id;
@dynamic total_count;
@dynamic clue_count;
@dynamic unread_count;
@dynamic sent;
@dynamic content_cache;
@synthesize messages;

+ (NSNumber*)nextFakeGabId
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(id < 0)"];
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Gabs"];
    request.includesSubentities = NO;
    request.predicate = pred;
    NSError *error;
    NSInteger count = [context countForFetchRequest:request error:&error];
    
    return [NSNumber numberWithInt:(-count-1)];
}

+ (YTGab*) createGabWithFriend:(YTFriend*)f andMessage:(NSString*)content ofKind:(NSInteger)kind
{
    YTGab* gab = [NSEntityDescription insertNewObjectForEntityForName:@"Gabs"
                                               inManagedObjectContext:[YTAppDelegate current].managedObjectContext];

    NSNumber* val = [YTGab nextFakeGabId];
    
    gab.related_user_name = f.name;
    gab.related_avatar = f.avatarUrl;
    gab.sent = [NSNumber numberWithBool:true];
    gab.clue_count = @0;
    gab.id = val;
    gab.total_count = @0;
    gab.unread_count = @0;
    gab.updated_at = [NSDate date];
    
    [[Mixpanel sharedInstance] track:@"Created Thread"];
    
    YTGabMessage* message = [gab createNewMessage:content ofKind:kind];
    
    YTGabPostOperation* postOp = [[YTGabPostOperation alloc] initWithGab:gab andMessage:message andFriend:f];
    
    [[YTGab messageOperationQueue] addOperation:postOp];
    return gab;
}

- (NSString*) gabTitle
{
    NSString *title = self.related_user_name;
    BOOL hasTitle = title && [title length] > 0;   
    return hasTitle ? title : @"???";
}

- (void)clearUnread
{
    if(![self isFakeGab]) {
        if(self.unread_count.integerValue != 0) {           
            [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@", self.id]
                                        method:@"POST"
                                        params:@{@"unread_count": @0, @"total_unread_count": @true}
                                       success:^(id JSON) {
                                           self.unread_count = @0;
                                           [YTAppDelegate.current.currentUser setUnreadCount:[JSON[@"total_unread_count"] integerValue]];
                                           [[NSNotificationCenter defaultCenter] postNotificationName:YTGabUpdated
                                                                                               object:self];
                                       }
                                       failure:nil];
            
        }
    }
}

+ (YTGab*) updateGab:(NSDictionary*)JSON
{

    YTGab *gab = [YTGab gabForId:JSON[@"id"]];
    
    if(JSON[@"related_user_name"])
        gab.related_user_name = JSON[@"related_user_name"];
    
    if(JSON[@"related_avatar"])
        gab.related_avatar = JSON[@"related_avatar"];
    
    if(JSON[@"content_cache"])
        gab.content_cache = JSON[@"content_cache"];
    
    if(JSON[@"content_summary"])
        gab.content_summary = JSON[@"content_summary"];
    
    if(JSON[@"unread_count"])
        gab.unread_count = JSON[@"unread_count"];
    
    if(JSON[@"total_count"])
        gab.total_count = JSON[@"total_count"];
    
    if(JSON[@"clue_count"])
        gab.clue_count = JSON[@"clue_count"];
    
    if(JSON[@"sent"])
        gab.sent = JSON[@"sent"];
        
    NSDate* old_update = gab.updated_at;
    NSDate* new_date = [YTHelper parseDate:JSON[@"updated_at"]];
    gab.updated_at = new_date;
    
    NSArray* messages = JSON[@"messages"];
    if(messages) {
        for(id message in messages) {
            [YTGabMessage parse:message];
        }

        [gab rebuildMessageArray];

        [[NSNotificationCenter defaultCenter] postNotificationName:YTGabMessageUpdated
                                                            object:gab];

        gab.needs_update = [NSNumber numberWithBool:false];
    }
    else {
        //if there wasn't an old update, we must be afresh pull - therefore we need messages since we didn't get any in thepacket
        if(!old_update)
            gab.needs_update = [NSNumber numberWithBool:true];
        else
        {
            //if it's already needs update, do nothing:
            if(!gab.needs_update.boolValue)
                //otherwise, if we weren't gonna update, check the updated_value
                gab.needs_update = [NSNumber numberWithBool:![old_update isEqualToDate:new_date]];
        }
    }
        
    return gab;
}

- (void) update:(BOOL)force failure:(void(^)(id JSON))failure
{
    if(![self isFakeGab] && (force || self.needs_update.boolValue)) {
        [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@", self.id]
                                    method:@"GET" params:@{@"extended":@true}
                                   success:^(id JSON) {
                                       [YTGab updateGab:JSON[@"gab"]];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:YTGabUpdated object:self];
                                   }
                                   failure:^(id JSON) {
                                       if(failure)
                                           failure(JSON);
                                   }];
    }
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:YTGabUpdated object:self];

}

- (YTGabMessage*) createNewMessage:(NSString*)content ofKind:(NSInteger)kind
{
    YTGabMessage* message = [NSEntityDescription insertNewObjectForEntityForName:@"Messages"
                                                          inManagedObjectContext:[YTAppDelegate current].managedObjectContext];
    message.content = content;
    message.kind = [NSNumber numberWithInt:kind];
    message.gab_id = self.id;
    message.key = [YTHelper randString:12];
    message.created_at = [YTHelper localDateInUtcDate:[NSDate date]];
    message.status = [NSNumber numberWithInt:YTGabMessageStatusDelivering];
    
    message.read = [NSNumber numberWithBool:YES];
    message.deleted = [NSNumber numberWithBool:NO];
    message.sent = [NSNumber numberWithBool:YES];
    
    [self rebuildMessageArray];

    return message;
}


- (void) postNewMessage:(NSString*)content ofKind:(NSInteger)kind
{
    YTGabMessage* message = [self createNewMessage:content ofKind:kind];
    
    [[YTAppDelegate current].managedObjectContext processPendingChanges];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YTGabMessageUpdated
                                                        object:self];

    [self postMessage:message];
}

- (void)rebuildMessageArray
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    NSError *error;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Messages"];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"created_at" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"(gab_id = %@ && deleted = false)", self.id];

    NSArray *objects = [context executeFetchRequest:request error:&error];
    self.messages = objects;
}

- (int)messageCount
{
    return self.messages.count;
}

- (YTGabMessage*) messageAtIndex:(int)index
{
    return [self.messages objectAtIndex:index];
}

- (bool)isFakeGab
{
    return self.id.integerValue < 0;
}

+ (YTGab*)gabForId:(NSNumber *)gab_id
{
    YTAppDelegate *delegate = [YTAppDelegate current];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Gabs"];
    request.predicate = [NSPredicate predicateWithFormat:@"(id = %@)", gab_id];
    
    NSArray *objects = [context executeFetchRequest:request error:&error];
    
    if(objects.count < 1) {
        YTGab* gab = [NSEntityDescription insertNewObjectForEntityForName:@"Gabs" inManagedObjectContext:context];
        gab.id = gab_id;
        return gab;
    }
    else
        return objects[0];
}

- (void)postMessage:(YTGabMessage *)message
{
    YTGabMessageDeliveryOperation* op = [[YTGabMessageDeliveryOperation alloc] initWithGabMessage:message];
    
    if([self isFakeGab]) {
        //find the job.
        YTGabPostOperation* postOperation = nil;
        NSArray* snapshot = [YTGab messageOperationQueue].operations;
        for(NSOperation* op in snapshot) {
            if([op isKindOfClass:[YTGabPostOperation class]]) {
                YTGabPostOperation* poss_op = (YTGabPostOperation*)op;
                if(poss_op.gab.id == self.id) {
                    //found it
                    postOperation = poss_op;
                    break;
                }
            }
        }
        
        if(postOperation) {
            //if it's nil, then the job completed in between we check and find
            [op addDependency:postOperation];
        }
    }

    [[YTGab messageOperationQueue] addOperation:op];
}

- (void) tag:(NSString*)tagString
{
    [YTApiHelper sendJSONRequestWithBlockingUIMessage:NSLocalizedString(@"Updating thread", nil)
                                                 path:[NSString stringWithFormat:@"/gabs/%@", self.id]
                                               method:@"POST"
                                               params:@{@"related_user_name": tagString}
                                              success:^(id JSON) {
                                                  YTGab* gab = [YTGab updateGab:JSON[@"gab"]];
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:YTGabUpdated
                                                                                                      object:gab];
                                              }
                                              failure:nil];
    [Flurry logEvent:@"Tagged_Thread"];
    [[Mixpanel sharedInstance] track:@"Tagged Thread"];
}

+ (NSOperationQueue*) messageOperationQueue
{
    static NSOperationQueue* messageOperationQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        messageOperationQueue = [[NSOperationQueue alloc] init];
        messageOperationQueue.name = @"Message Delivery Queue";
    });
    
    return messageOperationQueue;
}

- (void)awakeFromFetch
{
    [self rebuildMessageArray];
}

@end

NSString* const YTGabUpdated = @"YTGabUpdated";
NSString* const YTGabMessageUpdated = @"YTGabMessageUpdated";
