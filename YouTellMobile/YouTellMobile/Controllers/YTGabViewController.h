//
//  YTGabViewController.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "JSMessagesViewController.h"

#import "YTViewController.h"
#import "YTGabViewController.h"
#import "YTStoreHelper.h"
#import "YTGabPhotoHelper.h"
#import "YTGabClueHelper.h"
#import "YTGabTagHelper.h"
#import <CoreData/CoreData.h>
#import "YTFriend.h"
#import "YTGab.h"

@interface YTGabViewController : JSMessagesViewController <UINavigationControllerDelegate, JSMessagesViewDelegate, JSMessagesViewDataSource, JSDismissiveTextViewDelegate>
@property (nonatomic, retain) YTGab* gab;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) YTGabClueHelper *clueHelper;

- (id) initWithGab:(YTGab*)gab;
- (id) initWithFriend:(YTFriend*)f;

//TODO get rid of ytgabphotohelper
- (void)postNewMessage:(NSString*)content ofKind:(int)kind;
@end
