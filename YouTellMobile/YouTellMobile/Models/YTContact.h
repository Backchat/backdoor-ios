//
//  YTContact.h
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import <AddressBook/AddressBook.h>

@interface YTContact : NSObject <NSCopying>
@property (nonatomic, retain) NSString* first_name;
@property (nonatomic, retain) NSString* last_name;
@property (nonatomic, retain) NSString* value;
@property (nonatomic, retain) NSString* type;
@property (nonatomic, retain) NSString* phone_number;
@property (nonatomic, retain) UIImage* image;

@property (nonatomic, retain, readonly) NSString* name;
@property (nonatomic, retain, readonly) NSString* localizedType;
@property (nonatomic, strong, readonly) NSString* avatarUrl;

@end
