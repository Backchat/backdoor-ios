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
#import "YTGabTagHelper.h"
#import <CoreData/CoreData.h>


@interface YTGabViewController : JSMessagesViewController <UINavigationControllerDelegate, UIBubbleTableViewDataSource, UIAlertViewDelegate>

@property (strong, nonatomic) YTGabPhotoHelper *photoHelper;
@property (strong, nonatomic) YTGabClueHelper *clueHelper;
@property (strong, nonatomic) YTGabSendHelper *sendHelper;
@property (strong, nonatomic) YTGabTagHelper *tagHelper;
@property (strong, nonatomic) UIPopoverController *popover;

- (void)loadGab;
- (void)reloadData;
- (void)dismiss;
- (void)setGabId:(NSNumber*)gabId;

@property (nonatomic, retain) NSManagedObject* gab;

//LINREVIEW this is ugly we need to refactor the send queue code into a different helper
- (void)queueMessage:(NSString*)text ofKind:(NSInteger)kind;

@end
