//
//  NSBubbleData.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "NSBubbleData.h"
#import <QuartzCore/QuartzCore.h>

@implementation NSBubbleData

#pragma mark - Properties

@synthesize date = _date;
@synthesize type = _type;
@synthesize view = _view;
@synthesize insets = _insets;
@synthesize avatar = _avatar;

#pragma mark - Lifecycle

#if !__has_feature(objc_arc)
- (void)dealloc
{
    [_date release];
	_date = nil;
    [_view release];
    _view = nil;

    self.avatar = nil;

    [super dealloc];
}
#endif

#pragma mark - Text bubble

const UIEdgeInsets textInsetsMine = {5, 9, 10, 11};
const UIEdgeInsets textInsetsSomeone = {5, 11, 10, 9};

+ (id)dataWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithText:text date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithText:text date:date type:type];
#endif
}

- (id)initWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGSize size = [(text ? text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(220, 9999) lineBreakMode:NSLineBreakByWordWrapping];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.text = (text ? text : @"");
    label.font = font;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];

#if !__has_feature(objc_arc)
    [label autorelease];
#endif

    UIEdgeInsets insets = ((type == BubbleTypeMine || type == BubbleTypeMine2) ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:label date:date type:type insets:insets];
}

#pragma mark - Rich text bubble

- (id)initWithTextView:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
    const int UI_TEXTVIEW_MARGIN = 8;

    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

    int defaultWidth = 220;

    UITextView* textView = [[UITextView alloc] initWithFrame:CGRectMake(0,0, defaultWidth, 0)];
    textView.text = (text ? text : @"");
    textView.font = font;
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor whiteColor];
    textView.editable = NO;
    textView.scrollEnabled = NO;
    textView.contentInset = UIEdgeInsetsZero;

    textView.dataDetectorTypes = UIDataDetectorTypeAll;
#if !__has_feature(objc_arc)
    [textView autorelease];
#endif

    [textView sizeToFit];
    int width = textView.contentSize.width;
    
    if(textView.contentSize.height == 34) {//TODO stop hardcoding with a check against empty string textview size?
        //only one line, we need to resize to fit the width
        CGSize size = [(text ? text : @"") sizeWithFont:font];
        width = size.width + UI_TEXTVIEW_MARGIN*2; //for the margins
    }

    textView.frame = CGRectMake(0,0, width, textView.contentSize.height);


    UIEdgeInsets insets = ((type == BubbleTypeMine || type == BubbleTypeMine2) ? textInsetsMine : textInsetsSomeone);
    insets.left -= UI_TEXTVIEW_MARGIN;
    insets.right -= UI_TEXTVIEW_MARGIN;
    insets.top -= UI_TEXTVIEW_MARGIN;
    insets.bottom -= UI_TEXTVIEW_MARGIN;
    return [self initWithView:textView date:date type:type insets:insets];
}

+ (id)dataWithTextView:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithTextView:text date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithTextView:text date:date type:type];
#endif
}

#pragma mark - Image bubble

const UIEdgeInsets imageInsetsMine = {8,7,11,9};
const UIEdgeInsets imageInsetsSomeone = {8,9,11,7};

+ (id)dataWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithImage:image date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithImage:image date:date type:type];
#endif
}

- (id)initWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type
{
    CGSize size = image.size;
    if (size.width > 220)
    {
        size.height /= (size.width / 220);
        size.width = 220;
    }

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    imageView.image = image;
    imageView.layer.cornerRadius = 8.0;
    imageView.layer.masksToBounds = YES;


#if !__has_feature(objc_arc)
    [imageView autorelease];
#endif

    UIEdgeInsets insets = ((type == BubbleTypeMine || type == BubbleTypeMine2) ? imageInsetsMine : imageInsetsSomeone);
    return [self initWithView:imageView date:date type:type insets:insets];
}

#pragma mark - Custom view bubble

+ (id)dataWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithView:view date:date type:type insets:insets] autorelease];
#else
    return [[NSBubbleData alloc] initWithView:view date:date type:type insets:insets];
#endif
}

- (id)initWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets
{
    self = [super init];
    if (self)
    {
#if !__has_feature(objc_arc)
        _view = [view retain];
        _date = [date retain];
#else
        _view = view;
        _date = date;
#endif
        _type = type;
        _insets = insets;
    }
    return self;
}

@end
