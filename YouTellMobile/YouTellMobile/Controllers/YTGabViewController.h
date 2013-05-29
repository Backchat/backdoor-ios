//
//  YTGabViewController.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "JSMessagesViewController.h"

#import "UIBubbleTableView.h"

#import "YTViewController.h"
#import "YTGabViewController.h"
#import "YTStoreHelper.h"
#import "YTContactWidget.h"
#import "YTGabPhotoHelper.h"
#import "YTGabClueHelper.h"
#import "YTGabSendHelper.h"
#import "YTGabDeleteHelper.h"
#import "YTGabTagHelper.h"


@interface YTGabViewController : JSMessagesViewController <UINavigationControllerDelegate, UIBubbleTableViewDataSource>

@property (strong, nonatomic) YTGabPhotoHelper *photoHelper;
@property (strong, nonatomic) YTGabClueHelper *clueHelper;
@property (strong, nonatomic) YTGabSendHelper *sendHelper;
@property (strong, nonatomic) YTGabDeleteHelper *deleteHelper;
@property (strong, nonatomic) YTGabTagHelper *tagHelper;


@property (strong, nonatomic) NSNumber *gabId;
@property (strong, nonatomic) NSDictionary *receiverData;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) NSArray *messages;

- (void)loadGab;
- (void)reloadData;
- (void)dismiss;

@end
