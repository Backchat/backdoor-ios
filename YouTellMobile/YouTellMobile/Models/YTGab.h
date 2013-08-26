//
//  YTGab.h
//  Backdoor
//
//  Created by Lin Xu on 8/19/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "YTFriend.h"
#import "YTGabMessage.h"

enum {
    YTMessageKindText,
    YTMessageKindPhoto
};

@interface YTGab : NSManagedObject

+ (YTGab*) createGabWithFriend:(YTFriend*)f andMessage:(NSString*)content ofKind:(NSInteger)kind;

- (bool) isFakeGab;
- (void) clearUnread;
- (void) update:(BOOL)force;
- (void) rebuildMessageArray;

- (void) tag:(NSString*)string;

- (void) postNewMessage:(NSString*)content ofKind:(NSInteger)kind;

+ (YTGab*) updateGab:(NSDictionary*)JSON;
+ (YTGab*) gabForId:(NSNumber*)gab_id;

@property (nonatomic, retain, readonly) NSString* gabTitle;

@property (nonatomic, retain) NSDate* updated_at;
@property (nonatomic, retain) NSString* content_summary;
@property (nonatomic, retain) NSNumber* unread_count;
@property (nonatomic, retain) NSString* related_avatar;
@property (assign, nonatomic) NSNumber* sent;
@property (nonatomic, retain) NSNumber* id;
@property (nonatomic, assign) NSNumber* needs_update;
@property (nonatomic, retain) NSNumber* total_count;

@property (assign, nonatomic, readonly) int messageCount;
- (YTGabMessage*) messageAtIndex:(int)index;

+ (NSOperationQueue*) messageOperationQueue;
@end

extern NSString* const YTGabUpdated;
extern NSString* const YTGabMessageUpdated;