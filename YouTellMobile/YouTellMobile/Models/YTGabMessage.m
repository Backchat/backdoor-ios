//
//  YTGabMessage.m
//  Backdoor
//
//  Created by Lin Xu on 6/6/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTGabMessage.h"
#import "MF_Base64Additions.h"
#import "YTAppDelegate.h"
#import "YTHelper.h"

@interface YTGab ()
- (void) postMessage:(YTGabMessage*)message;
@end

@implementation YTGabMessage
@dynamic content;
@dynamic kind;
@dynamic gab_id;
@dynamic key;
@dynamic sent;
@dynamic created_at;
@dynamic status;
@dynamic read;
@dynamic secret;
@dynamic deleted;

- (UIImage*) image
{
    NSData *data = [NSData dataWithBase64String:self.content];
    UIImage *image = [UIImage imageWithData:data];
    return image;
}

+ (YTGabMessage*) messageForKey:(NSString*)key
{
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Messages"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(key = %@)", key];
    
    [request setPredicate:pred];
    
    NSError *error;
    
    NSArray *objects = [context executeFetchRequest:request error:&error];
    YTGabMessage* message;
    if ([objects count] > 0) {
        message = objects[0];
    } else {
        message = [NSEntityDescription insertNewObjectForEntityForName:@"Messages" inManagedObjectContext:context];
        message.key = key;
    }
    
    return message;
}

+ (YTGabMessage*) parse:(id)JSON
{
    YTGabMessage *message = [YTGabMessage messageForKey:JSON[@"key"]];
    message.status = JSON[@"status"];
    
    message.gab_id = JSON[@"gab_id"];
    message.content = JSON[@"content"];
    message.kind = JSON[@"kind"];
    message.secret = JSON[@"secret"];
    message.read = JSON[@"read"];
    message.deleted = JSON[@"deleted"];
    message.sent = JSON[@"sent"];
    message.created_at = [YTHelper parseDate:JSON[@"created_at"]];
    
    return message;
}

- (void) repostMessage
{
    if(self.status.integerValue != YTGabMessageStatusFailed)
        return;
    
    self.status = [NSNumber numberWithInt:YTGabMessageStatusDelivering];
    
    YTGab* gab = [YTGab gabForId:self.gab_id];
    [[NSNotificationCenter defaultCenter] postNotificationName:YTGabMessageUpdated
                                                        object:gab];
    
    [gab postMessage:self];
}
@end