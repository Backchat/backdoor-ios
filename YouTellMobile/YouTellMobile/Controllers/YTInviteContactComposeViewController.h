//
//  YTInviteContactComposeViewController.h
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTContact.h"

@interface YTInviteContactComposeViewController : UIViewController<UIAlertViewDelegate>
@property (nonatomic, retain) YTContact* contact;
@end
