//
//  YTAddressBookHelper.h
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTContacts.h"

@interface YTAddressBookHelper : NSObject
+ (void) fetchContactsFromAddressBookByContact:(YTContact*)contact success:(void(^)(YTContacts* c))success;
+ (void)fetchContacts:(void(^)(YTContacts* c))success;
@end
