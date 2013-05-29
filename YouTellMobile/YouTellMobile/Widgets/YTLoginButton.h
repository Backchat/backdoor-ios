//
//  YTLoginButton.h
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YTLoginButton : UIButton

@property (strong, nonatomic) NSString *type;

- (id)initWithType:(NSString*)type;
@end
