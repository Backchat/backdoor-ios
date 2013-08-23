//
//  YTHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#import "YTAppDelegate.h"

@interface YTHelper : NSObject

+ (NSDate *)localDateFromUtcDate:(NSDate*)utcDate;
+ (NSDate*)localDateInUtcDate:(NSDate*)localDate;
+ (NSString *)formatDate:(NSDate*)date;
+ (NSAttributedString *)formatDateAttr:(NSString*)date size:(CGFloat)size color:(UIColor*)color;

+ (NSInteger)ageWithBirthdayString:(NSString*)string format:(NSString*)format;
+ (NSDate *)parseDate:(NSString*)dateString;
+ (NSNumber *)parseNumber:(id)numberString;

+ (NSString *)hexStringFromData:(NSData*)data;
+ (NSString *)md5FromString:(NSString*)string;
+ (NSString*)randString:(NSInteger)length;

+ (UIImage *)imageNamed:(NSString *)imageName;
+ (BOOL)appStoreEnvironment;
+ (BOOL)simulatedEnvironment;
+ (bool)isPhone5;

+ (NSTimeInterval)keyboardAnimationDurationForNotification:(NSNotification*)notification;
@end
