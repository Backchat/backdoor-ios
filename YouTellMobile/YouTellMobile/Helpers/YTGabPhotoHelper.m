//
//  YTGabPhotoHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

//TODO refactor this into a controller...

#import <UIImage+Resize.h>
#import <Mixpanel.h>
#import <Base64/MF_Base64Additions.h>

#import "YTGabPhotoHelper.h"
#import "YTGabViewController.h"
#import "YTAppDelegate.h"
#import "YTPhotoSendViewController.h"
#import "YTHelper.h"

@interface YTGabPhotoHelper ()

@property (assign, nonatomic) NSInteger cameraPhotoButtonIndex;
@property (assign, nonatomic) NSInteger libraryPhotoButtonIndex;
@property (assign, nonatomic) NSInteger savedPhotoButtonIndex;

@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) UIImagePickerController *imagePicker;

@end

@implementation YTGabPhotoHelper

- (id)initWithGabView:(YTGabViewController*)gabView
{
    self = [super init];
    if (!self) {
        return self;
    }
    
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self.cameraButton setBackgroundImage:[YTHelper imageNamed:@"cambtn2.png"] forState:UIControlStateNormal];
    [self.cameraButton setBackgroundImage:[YTHelper imageNamed:@"cambtn3.png"] forState:UIControlStateHighlighted];
    
    [self.cameraButton sizeToFit];
    
    [self.cameraButton addTarget:self
                   action:@selector(cameraButtonWasPressed)
         forControlEvents:UIControlEventTouchUpInside];
    
    self.gabView = gabView;
    
    return self;
}

- (void)cameraButtonWasPressed
{
    self.cameraPhotoButtonIndex = -1;
    self.libraryPhotoButtonIndex = -1;
    self.savedPhotoButtonIndex = -1;
    
    
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.delegate = self;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.cameraPhotoButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"Take photo", nil)];
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.libraryPhotoButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"Choose existing", nil)];
    }
    
    /*
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        self.savedPhotoButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"Choose saved", nil)];
    }
     */
    
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    
    [sheet showFromRect:self.cameraButton.frame inView:self.gabView.inputToolBarView animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    imagePicker.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
    
    if (buttonIndex == self.cameraPhotoButtonIndex) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
    if (buttonIndex == self.libraryPhotoButtonIndex) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    if (buttonIndex == self.savedPhotoButtonIndex) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    
    self.imagePicker = imagePicker;
    
    /*TODO SPLIT if ([YTAppDelegate current].usesSplitView && (buttonIndex == self.savedPhotoButtonIndex || buttonIndex == self.libraryPhotoButtonIndex)) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
        [self.popover presentPopoverFromRect:self.gabView.inputView.cameraButton.frame inView:self.gabView.inputView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {*/
        if ([self.popover isPopoverVisible]) {
            [self.popover dismissPopoverAnimated:YES];
        }
        [self.gabView presentViewController:imagePicker animated:YES completion:nil];
    [self.gabView.inputToolBarView resignFirstResponder];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.gabView.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    YTPhotoSendViewController *photoView = [[YTPhotoSendViewController alloc]init];
    self.image = [self scaleImage:info[UIImagePickerControllerEditedImage]];
    
    if ([YTAppDelegate current].usesSplitView && [self.popover isPopoverVisible]) {
        [self.popover setContentViewController:photoView animated:YES];
    } else if ([YTAppDelegate current].usesSplitView) {
        [picker dismissViewControllerAnimated:YES completion:nil];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:photoView];
        [self.popover presentPopoverFromRect:self.cameraButton.frame inView:self.gabView.inputView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.gabView dismissViewControllerAnimated:NO completion:nil];
        [self.gabView presentViewController:photoView animated:YES completion:nil];
    }
    
    photoView.imageView.image = self.image;
    photoView.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    photoView.cancelButton.target = self;
    photoView.cancelButton.action = @selector(cancelButtonWasClicked);
    
    photoView.sendButton.target = self;
    photoView.sendButton.action = @selector(sendButtonWasClicked);
    
    [[Mixpanel sharedInstance] track:@"Selected Image"];
}

- (void)cancelButtonWasClicked
{
    if ([self.popover isPopoverVisible]) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self.gabView dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)sendButtonWasClicked
{
    [self cancelButtonWasClicked];
    //LINREVIEW this is memory intensive for very big images!! is base64 the right way here?
    NSData *data = UIImageJPEGRepresentation(self.image, 0.85);
    NSString* imageText = [data base64String];

    [self.gabView postNewMessage:imageText ofKind:YTMessageKindPhoto];
}

- (UIImage *)scaleImage:(UIImage*)image
{
    image = [self fixOrientation:image];
    
    float hfact = image.size.width / 1024.0f;
    float vfact = image.size.height / 768.0f;
    float factor = fmax(fmax(hfact, vfact), 1);
    CGSize size = CGSizeMake(image.size.width / factor, image.size.height / factor);
    
    UIImage *result = [image resizedImage:size transform:CGAffineTransformIdentity drawTransposed:NO interpolationQuality:kCGInterpolationHigh];
    
    return result;
}

- (UIImage *)fixOrientation:(UIImage*)image {

    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;

    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }

    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }

    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;

        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }

    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
