//
//  YTAddressBookHelper.m
//  Backdoor
//
//  Created by Lin Xu on 7/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTAddressBookHelper.h"

@implementation YTAddressBookHelper
+ (void) fetchContactsFromAddressBookByContact:(YTContact*)contact success:(void(^)(YTContacts* c))success;
{
    [YTAddressBookHelper addressBook:^(ABAddressBookRef ref) {
        YTContacts* contacts = [self contactsFromAddressBook:ref withContact:contact];
        if(success)
            success(contacts);
        
        CFRelease(ref);
    }];
}

+ (void) addressBook:(void(^)(ABAddressBookRef ref))handler
{
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);

    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if(granted) {
                handler(addressBookRef);
            }
            else {
                [YTAddressBookHelper askForPermissions];
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        handler(addressBookRef);
    }
    else {
        [YTAddressBookHelper askForPermissions];
    }
}

+ (void) askForPermissions
{
    UIAlertView* view = [[UIAlertView alloc] initWithTitle:@""
                                                   message:NSLocalizedString(@"Please allow Backchat access to your address book. Settings -> Privacy -> Contacts", nil)
                                                  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [view show];
}

+ (YTContacts*) contactsFromAddressBook:(ABAddressBookRef) addressBook withContact:(YTContact*)contact
{
    CFArrayRef people = ABAddressBookCopyPeopleWithName(addressBook, (__bridge CFStringRef)contact.name);
    
    YTContacts* ret = [YTAddressBookHelper contactsFromAddressBookRef:people];
    
    CFRelease(people);
    
    return ret;
}

+ (YTContacts*) contactsFromAddressBookRef:(CFArrayRef)people
{
    NSMutableArray* contacts = [[NSMutableArray alloc] init];
    for(CFIndex i=0;i<CFArrayGetCount(people);i++) {
        ABRecordRef* person = (ABRecordRef*) CFArrayGetValueAtIndex(people, i);
        NSString* first_name = (__bridge_transfer NSString*) ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString* last_name = (__bridge_transfer NSString*) ABRecordCopyValue(person, kABPersonLastNameProperty);
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);

        UIImage *image = nil;
        if(ABPersonHasImageData(person)) {
            NSData *imageData = (__bridge_transfer NSData*)ABPersonCopyImageData(person);
            image = [UIImage imageWithData:imageData];
        }
        
        NSMutableSet* set = [[NSMutableSet alloc] init];
        
        for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i);

            if(![set containsObject:phoneNumber]) {
                YTContact* c = [YTContact new];
                c.first_name = first_name ? first_name : @"";
                c.last_name = last_name ? last_name : @"";
                c.phone_number = phoneNumber;
                c.image = [image copy];
                c.socialID = [NSString stringWithFormat:@"AD:%d/%d", ABRecordGetRecordID(person), (int)i];
                
                [set addObject:phoneNumber];
                
                [contacts addObject:c];
            }
        }
        
        CFRelease(phoneNumbers);
    }
    
    return [[YTContacts alloc] initWithArray:contacts];
}

+ (void)fetchContacts:(void(^)(YTContacts* c))success
{
    [YTAddressBookHelper addressBook:^(ABAddressBookRef ref) {
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(ref);
        YTContacts* ret = [YTAddressBookHelper contactsFromAddressBookRef:people];
        success(ret);
        CFRelease(people);
        CFRelease(ref);
    }];
}
@end
