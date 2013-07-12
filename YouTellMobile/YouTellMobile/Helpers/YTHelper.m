//
//  YTHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <CommonCrypto/CommonDigest.h>

#import "YTHelper.h"
#import "YTAppDelegate.h"

@implementation YTHelper

+ (NSDate *)parseDate:(NSString*)dateString
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [formatter dateFromString:dateString];
    
    return date;
}


+ (NSInteger)ageWithBirthdayString:(NSString*)string
{
    if (!string) {
        return 0;
    }
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"MM/dd/yyyy";
    NSDate *birthDate = [formatter dateFromString:string];
    NSDate *curDate = [NSDate new];
    NSTimeInterval interval = [curDate timeIntervalSinceDate:birthDate];
    NSInteger result = interval / 60 / 60 / 24 / 365;
    return result;
}

+ (NSDate *)localDateFromUtcDate:(NSDate*)utcDate
{
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:utcDate];
    return [NSDate dateWithTimeInterval:seconds sinceDate:utcDate];
}

+ (NSString *)formatDate:(NSDate*)date
{
    NSDate *localDate = [YTHelper localDateFromUtcDate:date];
    NSDate *currentDate = [NSDate date];
    
    NSUInteger flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *localComp = [calendar components:flags fromDate:localDate];
    NSDateComponents *currentComp = [calendar components:flags fromDate:currentDate];
    
    NSTimeInterval interval = [currentDate timeIntervalSinceDate:localDate];
    
    NSDateFormatterStyle dateStyle;
    NSDateFormatterStyle timeStyle;
    
    NSString *result;
    
    if (localComp.day == currentComp.day && localComp.year == currentComp.year && localComp.month == currentComp.month) {
        dateStyle = NSDateFormatterNoStyle;
        timeStyle = NSDateFormatterShortStyle;
        result = [NSDateFormatter localizedStringFromDate:localDate dateStyle:dateStyle timeStyle:timeStyle];
    } else if (interval < (60 * 60 * 24 * 6)) {
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.dateFormat = @"EEEE";
        result = [formatter stringFromDate:localDate];
    } else {
        dateStyle = NSDateFormatterShortStyle;
        timeStyle = NSDateFormatterNoStyle;
        result = [NSDateFormatter localizedStringFromDate:localDate dateStyle:dateStyle timeStyle:timeStyle];
    }
    
    return result;
}

+ (NSAttributedString *)formatDateAttr:(NSString*)date size:(CGFloat)size color:(UIColor*)color
{
    NSRange fullRange = NSMakeRange(0, date.length);
    NSRange timeRange = ([date rangeOfString:@"\\d?\\d:\\d\\d" options:NSRegularExpressionSearch]);
    NSMutableAttributedString *ret = [[NSMutableAttributedString alloc] initWithString:date];
    
    [ret addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:size] range:fullRange];
    [ret addAttribute:NSForegroundColorAttributeName value:color range:fullRange];
    
    if (timeRange.location == 0) {
        [ret addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:size] range:timeRange];
    }
    
    return ret;
}

+ (NSNumber *)parseBool:(id)boolString
{
    BOOL cond = NO;
    if(boolString)
        cond = [boolString isEqualToString:@"t"];
    return [NSNumber numberWithBool:cond];
}

+ (NSNumber *)parseNumber:(id)numberString
{
    return [NSNumber numberWithInteger:[numberString integerValue]];
}

+ (NSString *)hexStringFromData:(NSData*)data
{
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];

    if (!dataBuffer)
        return [NSString string];

    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];

    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];

    return [NSString stringWithString:hexString     ];
}

+ (NSString *)md5FromString:(NSString*)string
{
    if (!string) string = @"";
    const char *ptr = [string UTF8String];
    unsigned char buf[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, strlen(ptr), buf);
    NSMutableString *res = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i=0;i<CC_MD5_DIGEST_LENGTH;++i) {
        [res appendFormat:@"%02x", buf[i]];
    }
    return res;
}

+ (void)simpleAlertWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil];
    [alert show];
}

+ (BOOL)appStoreEnvironment
{
    if ([YTHelper simulatedEnvironment]) {
        return NO;
    }
    
    if ([[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"]) {
        return NO;
    }
    
    return YES;
}

+ (BOOL)simulatedEnvironment
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (NSString*)randString:(NSInteger)length
{
    NSMutableString *ret = [[NSMutableString alloc] init];
    
    for (int i=0;i<length;++i) {
        [ret appendFormat:@"%c", 'A' + arc4random_uniform(25)];
    }
    
    return ret;
}

+ (bool)isPhone5
{
    return ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) &&
            ([UIScreen mainScreen].bounds.size.height > 480.0f));
}

+ (UIImage *)imageNamed:(NSString *)imageName
{    
    //are we on a iPhone5? if so, add the -568h
    //we assume no extension ".png"
    if  ([YTHelper isPhone5]) {
        NSMutableString *imageNameMutable = [imageName mutableCopy];

        [imageNameMutable appendString:@"-568h@2x"]; //iPhone5 must be retina
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageNameMutable ofType:@"png"];
        if (imagePath) {
            return [UIImage imageNamed:imageNameMutable];
        }
    }

    return [UIImage imageNamed:imageName];
}

@end