//
//  YTGabMessageDeliveryOperation.h
//  Backdoor
//
//  Created by Lin Xu on 8/21/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTGabMessage.h"

@interface YTGabMessageDeliveryOperation : NSOperation
- (id) initWithGabMessage:(YTGabMessage*)message;
@property (nonatomic, retain) YTGabMessage* message;
@end
