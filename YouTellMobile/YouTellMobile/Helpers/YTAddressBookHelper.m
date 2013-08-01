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
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if(granted) {
                YTContacts* contacts = [self contactsFromAddressBook:addressBookRef withContact:contact];
                if(success)
                    success(contacts);
            }
            else {
                [YTAddressBookHelper askForPermissions];
                success(nil);
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        YTContacts* contacts = [self contactsFromAddressBook:addressBookRef withContact:contact];
        if(success)
            success(contacts);
    }
    else {
        [YTAddressBookHelper askForPermissions];
        success(nil);
    }
}

+ (void) askForPermissions
{
    UIAlertView* view = [[UIAlertView alloc] initWithTitle:@""
                                                   message:NSLocalizedString(@"Please allow Backdoor access to your address book. Settings -> Privacy -> Contacts", nil)
                                                  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [view show];
}

+ (YTContacts*) contactsFromAddressBook:(ABAddressBookRef) addressBook withContact:(YTContact*)contact
{
    CFArrayRef people = ABAddressBookCopyPeopleWithName(addressBook, (__bridge CFStringRef)contact.name);
            
    NSMutableArray* contacts = [[NSMutableArray alloc] init];
    for(CFIndex i=0;i<CFArrayGetCount(people);i++) {
        ABRecordRef* person = (ABRecordRef*) CFArrayGetValueAtIndex(people, i);
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        NSString* first_name = (__bridge_transfer NSString*) ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString* last_name = (__bridge_transfer NSString*) ABRecordCopyValue(person, kABPersonLastNameProperty);
        UIImage *image = nil;
        if(ABPersonHasImageData(person)) {
            NSData *imageData = (__bridge_transfer NSData*)ABPersonCopyImageData(person);
            image = [UIImage imageWithData:imageData];
        }
        
        for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
            YTContact* c = [contact copy];
            c.first_name = first_name;
            c.last_name = last_name;
            c.phone_number = phoneNumber;
            c.image = [image copy];
            [contacts addObject:c];
        }
        
        CFRelease(phoneNumbers);
    }
    
    CFRelease(people);
    CFRelease(addressBook);
    
    return [[YTContacts alloc] initWithArray:contacts];
}
@end
