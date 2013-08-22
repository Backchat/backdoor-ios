//
//  YTGabPostOperation.m
//  Backdoor
//
//  Created by Lin Xu on 8/21/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTGabPostOperation.h"
#import "YTApiHelper.h"
#import "YTGabMessageDeliveryOperation.h"

@interface YTGabPostOperation ()
@property (nonatomic, retain) YTFriend* friend;
@property (nonatomic, retain) YTGabMessage* message;
@end

@implementation YTGabPostOperation
- (id) initWithGab:(YTGab*)gab andMessage:(YTGabMessage *)message andFriend:(YTFriend *)f
{
    if(self = [super init]) {
        self.gab = gab;
        self.friend = f;
        self.message = message;
    }
    return self;
}

- (void)main
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    [params setValue:@{@"content": self.message.content,
     @"kind": self.message.kind,
     @"key": self.message.key} forKey:@"message"];
    
    if(self.friend.isFault || self.friend.isDeleted) {
        //friend was deleted under us
        //TODO show a proper message.
        //for now,
        return;
    }
    
    if(self.friend.isFriend) {
        [params setValue:@{@"id": self.friend.id} forKey:@"friendship"];
    }
    else {
        [params setValue:@{@"id": self.friend.featured_id} forKey:@"featured"];
    }
       
    dispatch_semaphore_t wait = dispatch_semaphore_create(0);
    
    [YTApiHelper sendJSONRequestToPath:@"/gabs" method:@"POST" params:params
                               success:^(id JSON) {
                                   id new_id = JSON[@"gab"][@"id"];
                                   id old_id = self.gab.id;
                                   //update the original gab to use the new_id
                                   self.gab.id = new_id;

                                   //update the original message to use the new_id
                                   self.message.gab_id = new_id;
                                   
                                   //update all pending messages
                                   //TODO hold this list ourselves?
                                   for(NSOperation* op in [YTGab messageOperationQueue].operations) {
                                       if([op isKindOfClass:[YTGabMessageDeliveryOperation class]]) {
                                           YTGabMessageDeliveryOperation* dop = (YTGabMessageDeliveryOperation*)op;
                                           if(dop.message.gab_id == old_id) {
                                               dop.message.gab_id = new_id;
                                           }
                                       }
                                   }
                                   
                                   [YTGab updateGab:JSON[@"gab"]];                                   
                                   
                                   //let everyone know
                                   [[NSNotificationCenter defaultCenter] postNotificationName:YTGabUpdated object:self.gab];
                                   
                                   dispatch_semaphore_signal(wait);
                               }
                               failure:^(id JSON) {
                                   dispatch_semaphore_signal(wait);                                   
                               }];
    
    dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER);
    dispatch_release(wait);
}
@end
