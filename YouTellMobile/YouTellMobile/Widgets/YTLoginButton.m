//
//  YTLoginButton.m
//  Backdoor
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "YTLoginButton.h"
#import "YTHelper.h"


@implementation YTLoginButton

- (id)initWithType:(NSString*)type
{
    self = [super init];
    if (!self) {
        return self;
    }
    
    self.type = type;

    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    
    if ([type isEqualToString:@"facebook"]) {
        
        [self setBackgroundImage:[[YTHelper imageNamed:@"btn_white_inactive"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)] forState:UIControlStateNormal];
        [self setBackgroundImage:[[YTHelper imageNamed:@"btn_white_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)] forState:UIControlStateHighlighted];

        [self setTitle:NSLocalizedString(@"Sign in with Facebook", nil) forState:UIControlStateNormal];
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];


    } else {

        [self setTitle:NSLocalizedString(@"Sign in with Google", nil) forState:UIControlStateNormal];
        
        [self setBackgroundImage:[[YTHelper imageNamed:@"btn_black_inactive"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)] forState:UIControlStateNormal];
        
        [self setBackgroundImage:[[YTHelper imageNamed:@"btn_black_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)] forState:UIControlStateHighlighted];
        
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    }
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    
    /*
    self.layer.cornerRadius = 10;
    self.layer.borderWidth = 1.0f;
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    self.layer.shadowOpacity = 0.5f;
    self.layer.shadowRadius = 2.0f;
     */

    [self setHighlighted:NO];
    return self;
}

/*
- (void)setHighlighted:(BOOL)highlighted
{
    if ([self.type isEqualToString:@"facebook"]) {
        self.backgroundColor = (highlighted)
        ? [UIColor colorWithRed:0x2b*0.8/256.0f green:0x50*0.8/256.0f blue:0x9a*0.8/256.0f alpha:1.0f]
        : [UIColor colorWithRed:0x2b/256.0f green:0x50/256.0f blue:0x9a/256.0f alpha:1.0f];
    } else {
        self.backgroundColor = (highlighted)
        ? [UIColor colorWithRed:0xBC*0.8/256.0f green:0x0C*0.8/256.0f blue:0x0C*0.8/256.0f alpha:1.0f]
        : [UIColor colorWithRed:0xBC/256.0f green:0x0C/256.0f blue:0x0C/256.0f alpha:1.0f];
    }
    return [super setHighlighted:highlighted];
}
 */

@end
