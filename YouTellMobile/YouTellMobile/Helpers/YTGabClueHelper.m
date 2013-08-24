//
//  YTGabClueHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <UIButton+WebCache.h>
#import <Mixpanel.h>

#import "YTGabClueHelper.h"

#import "YTModelHelper.h"
#import "YTGabViewController.h"
#import "YTApiHelper.h"
#import "YTStoreHelper.h"
#import "YTAppDelegate.h"
#import "YTConfig.h"
#import "YTSheetViewController.h"
#import "YTViewHelper.h"
#import "YTHelper.h"

@implementation YTGabClueHelper

- (id)initWithGabView:(YTGabViewController*)gabView
{
    self = [super init];
    if (!self) {
        return self;
    }
    self.gabView = gabView;
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.hidesWhenStopped = YES;
    CGRect frame = self.activityIndicator.frame;
    frame.origin.x = 11;
    frame.origin.y = 11;
    self.activityIndicator.frame = frame;
    
    return self;
}

- (UIBarButtonItem*)setupClueButton
{
    self.button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clue", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(actionButtonWasPressed:)];
    return self.button;
}

# pragma mark Button handler methods

- (void)requestClueButtonWasPressed:(id)sender
{
    UIButton *button = (UIButton*)sender;
    NSNumber *number = [NSNumber numberWithInt:(button.tag - 100)];
    UILabel *label = (UILabel*)[self.sheet.sheetView viewWithTag:button.tag - 100 + 1000];
    NSDictionary *clues = [YTModelHelper cluesForGab:[self.gabView.gab valueForKey:@"id"]];
    NSDictionary *clue = clues[number];
    NSInteger availClues = [YTModelHelper userAvailableClues];
    
    if (clue) {
        //CGSize size = [label.text sizeWithFont:label.font];
        //if (size.width <= label.bounds.size.width) {
        //    return;
        //}
        NSString *field = clue[@"field"];
        NSString *fieldText = @{
                                @"gender": NSLocalizedString(@"Gender", nil),
                                @"school": NSLocalizedString(@"School", nil),
                                @"location": NSLocalizedString(@"Location", nil),
                                @"work": NSLocalizedString(@"Work", nil),
                                @"like": NSLocalizedString(@"Likes", nil)
                                }[field];
        NSString *text;
        
        if (fieldText) {
            text = [NSString stringWithFormat:@"%@: %@", fieldText, label.text];
        } else {
            text = label.text;
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:text delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (availClues == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"You have no remaining clues", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [button setBackgroundImage:[YTHelper imageNamed:@"clue_blank"] forState:UIControlStateNormal];
    [self.activityIndicator removeFromSuperview];
    [button addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
    
    [YTApiHelper requestClue:[self.gabView.gab valueForKey:@"id"] number:number success:^(id JSON) {
        [self.activityIndicator stopAnimating];
        //TODO improve this so we only update the right button...jeez        
        [self updateClues];
        
        if ([JSON[@"success"] isEqualToNumber:@0]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"You have no remaining clues", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alert show];
            return;
        }
        
    }];
}

- (void)buyCluesButtonWasPressed
{   
    [self.sheet dismiss];
    if(![YTAppDelegate current].storeHelper) {
        [YTAppDelegate current].storeHelper = [YTStoreHelper new];
    }
    [[YTAppDelegate current].storeHelper showFromBarButtonItem:self.button];
}

- (void)cancelButtonWasPressed
{
    [self.sheet dismiss];
}

- (void)actionButtonWasPressed:(id)sender
{
    [[Mixpanel sharedInstance] track:@"Tapped Gab View / Clue Button"];

    [self.gabView.view.window endEditing:YES];;

    UILabel *label;
    CGRect frame;
    CGFloat width = self.gabView.view.frame.size.width;
    CGFloat height = 0;
    
    
    self.sheet = [[YTSheetViewController alloc] init];
    UIView *sheetView = self.sheet.sheetView;
    
    
    // View background
    
    UIView *bgView = [[UIView alloc] init];
    bgView.tag = 13;
    bgView.backgroundColor = [UIColor colorWithRed:63/255.0 green:173/255.0 blue:30/255.0 alpha:1];
    [sheetView addSubview:bgView];
    
    
    // Header background
    
    UIImageView *hdrImage = [[UIImageView alloc] initWithImage:[YTHelper imageNamed:@"clue_header"]];
    hdrImage.frame = CGRectMake(0, 0, width, 44);
    [sheetView addSubview:hdrImage];

    
    // Header label
    
    label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:17];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.tag = 10;
    label.textAlignment = NSTextAlignmentCenter;
    [label sizeToFit];
    frame = label.frame;
    frame.origin.y = 0;
    frame.origin.x = 0;
    frame.size.width = [UIScreen mainScreen].bounds.size.width;
    frame.size.height = 40;
    label.frame = frame;
    [sheetView addSubview:label];
    height += 60;
    
    NSManagedObject *gab = self.gabView.gab;
    NSInteger clue_count = [[gab valueForKey:@"clue_count"] integerValue];
    
    // Clue buttons

    for (int k=0;k<clue_count;++k) {
        int i = k % 3;
        
        if (i == 0 && k != 0) {
            height += 90;
        }
        UIView *shadow = [[UIView alloc] init];
        frame = shadow.frame;
        frame.size.width = 60;
        frame.size.height = 60;
        frame.origin.x = 38 + i * 90;
        frame.origin.y = height;
        shadow.frame = frame;
        shadow.layer.shadowColor = [[UIColor whiteColor] CGColor];
        shadow.layer.shadowRadius = 4.0f;
        shadow.layer.shadowOpacity = 0.8f;
        shadow.layer.shadowOffset = CGSizeZero;
        shadow.layer.masksToBounds = NO;
        shadow.tag = 10000 + k;
            
            
        UIButton *button = [[UIButton alloc] init];
        [button setBackgroundImage:[YTHelper imageNamed:@"clue_hidden2"] forState:UIControlStateNormal];
        button.frame = CGRectMake(0,0,60,60);
        button.tag = 100 + k;
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 7;
        [button addTarget:self action:@selector(requestClueButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
            
        [sheetView addSubview:shadow];
        [shadow addSubview:button];
        
            
        UILabel *clabel = [[UILabel alloc] init];
        frame.origin.y += 63;
        frame.origin.x -= 10;
        frame.size.width += 20;
        frame.size.height = 15;
        clabel.frame = frame;
        clabel.backgroundColor = [UIColor clearColor];
        clabel.textColor = [UIColor whiteColor];
        clabel.textAlignment = NSTextAlignmentCenter;
        clabel.font = [UIFont boldSystemFontOfSize:12];
        clabel.tag = 1000 + k;
        [sheetView addSubview:clabel];
    }

    height += 90;
    
    // Buy Clues button
    
    UIButton *buyButton = [[UIButton alloc] init];
    buyButton.tag = 11;
    [buyButton setBackgroundImage:[YTHelper imageNamed:@"clue_button_inactive"] forState:UIControlStateNormal];
    [buyButton setBackgroundImage:[YTHelper imageNamed:@"clue_button_active"] forState:UIControlStateHighlighted];
    frame.origin.y = height;
    frame.size.width = 280;
    frame.size.height = 40;
    frame.origin.x = (width - frame.size.width) / 2;
    buyButton.frame = frame;
    [buyButton setTitle:NSLocalizedString(@"Buy clues", nil) forState:UIControlStateNormal];
    [buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    buyButton.titleLabel.font = [UIFont boldSystemFontOfSize:19];
    [sheetView addSubview:buyButton];
    [buyButton addTarget:self action:@selector(buyCluesButtonWasPressed) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self shouldDisplayBuyButton]) {
        height += 50;
    } else {
        buyButton.hidden = YES;
    }
    
    // Cancel button
    
    UIButton *cancelButton = [[UIButton alloc] init];
    cancelButton.tag = 12;
    [cancelButton setBackgroundImage:[YTHelper imageNamed:@"clue_button_inactive"] forState:UIControlStateNormal];
    [cancelButton setBackgroundImage:[YTHelper imageNamed:@"clue_button_active"] forState:UIControlStateHighlighted];
    frame.origin.y = height;
    frame.size.width = 280;
    frame.size.height = 40;
    frame.origin.x = (width - frame.size.width) / 2;
    cancelButton.frame = frame;
    [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:19];
    [cancelButton addTarget:self action:@selector(cancelButtonWasPressed) forControlEvents:UIControlEventTouchUpInside];
    [sheetView addSubview:cancelButton];
    height += 50;
    
    height += 10;
    
    // View frame
    
    frame = sheetView.frame;
    frame.size.width = width;
    frame.size.height = height;
    sheetView.frame = frame;
    bgView.frame = frame;
    
    [self updateClues];

    
    [self.sheet present];

}

- (void)updateClues
{    
    UILabel *label = (UILabel*)[self.sheet.sheetView viewWithTag:10];

    [YTApiHelper getCluesForGab:[self.gabView.gab valueForKey:@"id"] success:^(id JSON) {
        NSInteger availClues = [YTModelHelper userAvailableClues];
        label.text = [NSString stringWithFormat:NSLocalizedString(@"You have %d clues remaining", nil), availClues];
        
        NSDictionary *clues = [YTModelHelper cluesForGab:[self.gabView.gab valueForKey:@"id"]];

        for (int i=0;i<9;++i) {
            NSNumber *n = [NSNumber numberWithInt:i];
            NSDictionary *clue = clues[n];
            UIView *shadow = (UIView*)[self.sheet.sheetView viewWithTag:10000+i];
            shadow.layer.shadowRadius = clue ? 0 : 4;
            [self updateClue:clue number:n];
        }
        
        [self updateBuyButton];
        
    }];

}

- (void)updateClue:(NSDictionary *)clue number:(NSNumber*)number
{

    NSInteger i = [number integerValue];
    UILabel *label = (UILabel*)[self.sheet.sheetView viewWithTag:(1000 + i)];
    UIButton *button = (UIButton*)[self.sheet.sheetView viewWithTag:(100 + i)];
    NSDictionary *parsed = [self parseClueValue:clue];
    NSString *url = parsed[@"url"];
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale == 1.0) {
        url = [url stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
    }

    label.text = parsed[@"text"];
    [button setBackgroundImageWithURL:[NSURL URLWithString:url] forState:UIControlStateNormal placeholderImage:[YTHelper imageNamed:@"clue_hidden2"]];

}

- (void)updateBuyButton
{
    BOOL doshow = [self shouldDisplayBuyButton];
    
    UIView *sheetView = self.sheet.sheetView;
    UIButton *buyButton = (UIButton*)[sheetView viewWithTag:11];
    UIButton *cancelButton = (UIButton*)[sheetView viewWithTag:12];
    UIView *bgView = [sheetView viewWithTag:13];
    CGFloat height = 50;
    
    if (doshow && !buyButton.hidden) {
        return;
    }
    
    if (!doshow && buyButton.hidden) {
        return;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        CGRect frame;
        NSInteger factor = doshow ? 1 : -1;
       
        frame = cancelButton.frame;
        frame.origin.y += height * factor;
        cancelButton.frame = frame;
            
        frame = sheetView.frame;
        frame.size.height += height * factor;
        frame.origin.y -= height * factor;
        sheetView.frame = frame;
            
        frame = bgView.frame;
        frame.size.height += height * factor;
        bgView.frame = frame;
        
        buyButton.hidden = !doshow;
    }];
    
}

- (BOOL)shouldDisplayBuyButton
{
    // return ([YTModelHelper userAvailableClues] == 0);
    return YES;
}

- (NSDictionary*)parseClueValue:(NSDictionary *)clue
{
    if (!clue) {
        return @{@"text": @"", @"url": @""};
    }
    
    NSString *value = clue[@"value"];
    NSString *field = clue[@"field"];
    
    NSMutableArray *parts = [NSMutableArray arrayWithArray:[value componentsSeparatedByString:@"|"]];
    NSMutableDictionary *ret = [NSMutableDictionary new];
    if (parts.count == 1) {
        ret[@"text"] = parts[0];
        ret[@"url"] = @"";
    } else {
        ret[@"url"] = parts[0];
        [parts removeObjectAtIndex:0];
        ret[@"text"] = [parts componentsJoinedByString:@"|"];
    }
    
    if ([field isEqualToString:@"gender"] && [ret[@"text"] isEqualToString:@"male"]) {
        ret[@"text"] = NSLocalizedString(@"Male", nil);
    }
    
    if ([field isEqualToString:@"gender"] && [ret[@"text"] isEqualToString:@"female"]) {
        ret[@"text"] = NSLocalizedString(@"Female", nil);
    }

    if ([field isEqualToString:@"age"]) {
        ret[@"text"] = [NSString stringWithFormat:NSLocalizedString(@"Age: %@", nil), ret[@"text"]];
    }
    
    return ret;
}


@end
