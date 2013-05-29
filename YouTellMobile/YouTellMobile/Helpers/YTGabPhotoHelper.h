//
//  YTGabPhotoHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YTGabViewController;

@interface YTGabPhotoHelper : NSObject <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) YTGabViewController *gabView;

@property (assign, nonatomic) NSInteger cameraPhotoButtonIndex;
@property (assign, nonatomic) NSInteger libraryPhotoButtonIndex;
@property (assign, nonatomic) NSInteger savedPhotoButtonIndex;

@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIImage *image;

- (id)initWithGabView:(YTGabViewController*)gabView;
- (void)cameraButtonWasPressed;


@end
