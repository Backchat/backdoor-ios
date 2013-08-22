//
//  YTGabMessageDeliveryOperation.m
//  Backdoor
//
//  Created by Lin Xu on 8/21/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTGabMessageDeliveryOperation.h"
#import "YTHelper.h"
#import "YTApiHelper.h"
#import <Mixpanel.h>
#import <Flurry.h>

@interface YTGabMessageDeliveryOperation ()
@end

@implementation YTGabMessageDeliveryOperation
- (id) initWithGabMessage:(YTGabMessage*)message
{
    if(self = [super init]) {
        self.message = message;
    }
    return self;
}

- (void)main
{
    NSDictionary* params = @{@"content": self.message.content,
                             @"kind": self.message.kind,
                             @"key": self.message.key};
    
    dispatch_semaphore_t wait = dispatch_semaphore_create(0);
    
    [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@/messages", self.message.gab_id]
                                method:@"POST" params:params
                               success:^(id JSON) {
                                   //TODO get rid of this...
                                   [YTAppDelegate current].deliveredMessages[self.message.key] = [NSDate date];
                                   
                                   YTGabMessage* msg = [YTGabMessage parse:JSON[@"message"]];
                                   
                                   NSNumber *gabSent = [NSNumber numberWithBool:![msg.sent isEqualToNumber:@0]];
                                   
                                   [Flurry logEvent:@"Sent_Message" withParameters:@{@"kind":msg.kind}];
                                   [[Mixpanel sharedInstance] track:@"Sent Message" properties:@{@"Anonymous": gabSent}];
                                   
                                   [[NSNotificationCenter defaultCenter] postNotificationName:YTGabMessageUpdated
                                                                                       object:[YTGab gabForId:msg.gab_id]];
                                   
                                   dispatch_semaphore_signal(wait);
                               }
                               failure:^(id JSON) {
                                   dispatch_semaphore_signal(wait);
                                   //[YTModelHelper failMessage:key];
                               }];
    
    dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER);
    dispatch_release(wait);
}
@end
