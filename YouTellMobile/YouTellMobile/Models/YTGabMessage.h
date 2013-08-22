//
//  YTGabMessage.h
//  Backdoor
//
//  Created by Lin Xu on 6/6/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface YTGabMessage : NSManagedObject
@property (retain, nonatomic) NSString* content;
@property (retain, nonatomic) NSNumber* kind;
@property (retain, nonatomic) NSNumber* gab_id;
@property (retain, nonatomic) NSString* key;
@property (retain, nonatomic) NSDate* created_at;
@property (assign, nonatomic) NSNumber* sent;
@property (retain, nonatomic) NSNumber* status;
@property (retain, nonatomic) NSString* secret;
@property (retain, nonatomic) NSNumber* read;
@property (retain, nonatomic) NSNumber* deleted;

- (UIImage*) image;

+ (YTGabMessage*) parse:(id)JSON;
@end
