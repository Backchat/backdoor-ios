//
//  YTGabDeleteHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import "YTGabDeleteHelper.h"
#import "YTAppDelegate.h"
#import "YTApiHelper.h"
#import "YTViewHelper.h"

@implementation YTGabDeleteHelper

- (id)initWithGabView:(YTGabViewController*)gabView
{
    self = [super init];
    if (!self) {
        return self;
    }
    self.gabView = gabView;
    
    return self;
}

- (void)setupDeleteButton
{
    UIBarButtonItem *deleteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteButtonWasPressed:)];

    NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.gabView.navigationItem.rightBarButtonItems];
    [buttons insertObject:deleteBarButtonItem atIndex:0];
    self.gabView.navigationItem.rightBarButtonItems = buttons;
}

# pragma mark Button handler methods

- (void)deleteButtonWasPressed:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: NSLocalizedString(@"Clear conversation", nil)
                          message: NSLocalizedString(@"Are you sure you want to delete all messages in this conversation?", nil)
                          delegate: self
                          cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                          otherButtonTitles: NSLocalizedString(@"Clear", nil), nil
                          ];
   [alert show];
}


# pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    //LINREVIEW: is this even used?!
    [YTApiHelper deleteGab:[self.gabView.gab valueForKey:@"id"] success:^(id JSON) {
        YTAppDelegate *delegate = [YTAppDelegate current];
        [delegate.currentMainViewController deselectSelectedGab:YES];
        [YTViewHelper refreshViews];
        if (delegate.usesSplitView) {
            delegate.detailsController.viewControllers = @[[YTViewController new]];
        } else {
            [delegate.navController popViewControllerAnimated:YES];
        }
        
    }];
}


@end