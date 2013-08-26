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

@property (strong, nonatomic) UIButton* cameraButton;

@property (strong, nonatomic) UIImage *image;

- (id)initWithGabView:(YTGabViewController*)gabView;
- (void)cameraButtonWasPressed;


@end
