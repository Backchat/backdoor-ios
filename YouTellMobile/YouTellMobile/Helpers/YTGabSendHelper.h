//
//  YTGabSendHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YTContactWidget.h"

@class YTGabViewController;
@class YTContactWidget;

enum {
    YTMessageKindText,
    YTMessageKindPhoto
};

@interface YTGabSendHelper : NSObject <YTContactWidgetDelegate, UITextFieldDelegate>

@property (weak, nonatomic) YTGabViewController *gabView;

@property (strong, nonatomic) YTContactWidget *contactWidget;
@property (strong, nonatomic) UITableView *contactTable;
@property (strong, nonatomic) UIPopoverController *popover;

@property (strong, nonatomic) NSString *content;
@property (assign, nonatomic) NSInteger kind;

- (id)initWithGabView:(YTGabViewController*)gabView;
- (void)updateButtons;
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text;
- (void)keyboardWillShowHide:(NSNotification *)notification;

- (void)setTextContent:(NSString *)text;
- (void)setPhotoContent:(UIImage *)image;

- (void)sendMessage;
- (void)sendMessageCallback:(NSDictionary*)receiverData;
@end
