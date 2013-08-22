//
//  YTGabPostOperation.h
//  Backdoor
//
//  Created by Lin Xu on 8/21/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTGab.h"
#import "YTGabMessage.h"
#import "YTFriend.h"

@interface YTGabPostOperation : NSOperation
- (id) initWithGab:(YTGab*)gab andMessage:(YTGabMessage*)message andFriend:(YTFriend*)f;
@property (nonatomic, retain) YTGab* gab;
@end
