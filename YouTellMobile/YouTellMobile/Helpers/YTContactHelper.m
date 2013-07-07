//
//  YTContactHelper.m
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import <SDWebImage/UIImageView+WebCache.h>

#import "YTContactHelper.h"
#import "YTModelHelper.h"
#import "YTViewHelper.h"
#import "YTHelper.h"

@implementation YTContactHelper

+ (YTContactHelper*)sharedInstance
{
    static YTContactHelper *instance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        instance = [YTContactHelper new];
    });
    return instance;
}

- (void)setup
{
    [YTModelHelper clearContactsWithType:nil];
    [self loadAddressBook];
    self.randomizedFriends = [NSMutableArray new];
    self.filteredRandomizedFriends = [NSArray new];
}

- (NSArray *)arrayFromAB:(ABRecordRef)record property:(ABPropertyID)property;
{
    ABMultiValueRef items = ABRecordCopyValue(record, property);
    
    if (items == nil) {
        return @[];
    }
    
    CFIndex count = ABMultiValueGetCount(items);
    NSMutableArray *ret = [NSMutableArray new];
    
    for (CFIndex i = 0;i<count;++i) {
        NSString *value = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(items, i);
        if (value == nil) {
            value = @"";
        }
        CFStringRef label = ABMultiValueCopyLabelAtIndex(items, i);
        if (label == nil) {
            continue;
        }
        NSString *localizedLabel = (__bridge_transfer NSString*) ABAddressBookCopyLocalizedLabel(label);
        CFRelease(label);
        [ret addObject:@[localizedLabel, value]];
    }
    
    CFRelease(items);
    
    return ret;
}

- (void)loadAddressBookCB:(ABAddressBookRef)addressBook accessGranted:(BOOL)accessGranted
{
    if (!accessGranted) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Contacts", nil) message:NSLocalizedString(@"You can change this later in Settings > Privacy > Backdoor", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        CFRelease(addressBook);
        return;
    }
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    if (people == nil) {
        return;
    }
    
    ABRecordRef person;
    CFIndex count = ABAddressBookGetPersonCount(addressBook);
    
    for (int i=0;i<count;++i) {
        person = CFArrayGetValueAtIndex(people, i);
        
        NSString *first = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        if (first == nil) {
            first = @"";
        }
        
        NSString *last = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
        if (last == nil) {
            last = @"";
        }
        
        NSString *name;
        
        if ([first length] == 0 && [last length] == 0) {
            continue;
        } else if ([first length] == 0) {
            name = last;
        } else if ([last length] == 0) {
            name = first;
        } else {
            name = [[NSString alloc] initWithFormat:@"%@ %@", first, last];
        }
        
        NSArray *emails = [self arrayFromAB:person property:kABPersonEmailProperty];
        NSArray *phones = [self arrayFromAB:person property:kABPersonPhoneProperty];
        
        NSMutableDictionary *data;
        
        NSDictionary *base = @{
                               @"name": name,
                               @"first_name": first,
                               @"last_name": last
                               };
        
        for (NSArray *email in emails) {
            data = [[NSMutableDictionary alloc] initWithDictionary:base];
            data[@"title"] = email[0];
            data[@"value"] = email[1];
            data[@"type"] = @"email";
            [YTModelHelper addContactWithData:data];
        }
        
        for (NSArray *phone in phones) {
            data = [[NSMutableDictionary alloc] initWithDictionary:base];
            data[@"title"] = phone[0];
            data[@"value"] = phone[1];
            data[@"type"] = @"phone";
            [YTModelHelper addContactWithData:data];
        }
    }
    
    CFRelease(addressBook);
    CFRelease(people);
    
    [YTModelHelper save];
}

- (void)loadAddressBook
{
	return;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    ABAddressBookRef addressBook = ABAddressBookCreate();
#pragma clang diagnostic pop

    if (!addressBook) {
        return;
    }
   
    if (ABAddressBookRequestAccessWithCompletion == nil) {
        return [self loadAddressBookCB:addressBook accessGranted:YES];
    }
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        return [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self loadAddressBookCB:addressBook accessGranted:granted];
        }];
    });
}

- (void)addRandomizedFriends:(NSArray *)friends
{
    NSMutableArray *myFriends = [NSMutableArray arrayWithArray:friends];
    for (int x=0;x<[myFriends count];++x) {
        int r = (arc4random() % ([myFriends count] - x)) + x;
        [myFriends exchangeObjectAtIndex:x withObjectAtIndex:r];
    }
    [self.randomizedFriends addObjectsFromArray:myFriends];
    [self filterRandomizedFriends];
}

- (void)filterRandomizedFriends
{
    NSSet *names = [YTModelHelper gabReceiverNames];
    NSMutableArray *myFriends = [NSMutableArray new];
    for (NSDictionary *friend in self.randomizedFriends) {
        if ([names containsObject:friend[@"name"]]) {
            continue;
        }
        [myFriends addObject:friend];
    }
    self.filteredRandomizedFriends = myFriends;
    [YTViewHelper refreshViews];
}

- (void)loadFacebookFriends:(NSArray*)friends;
{
    [YTModelHelper clearContactsWithType:@"facebook"];
    
    NSMutableArray *myFriends = [NSMutableArray new];
    
    for (NSDictionary *friend in friends) {
        NSDictionary *data = @{
            @"name": friend[@"name"],
            @"first_name": friend[@"first_name"],
            @"last_name": friend[@"last_name"],
            @"type": @"facebook",
            @"title": NSLocalizedString(@"Facebook", nil),
            @"value": friend[@"id"],
        };
        [YTModelHelper addContactWithData:data];
        
        [myFriends addObject:@{@"type": @"facebook", @"value": friend[@"id"], @"name": friend[@"name"]}];
    };
    
    [self addRandomizedFriends:myFriends];

    [[YTAppDelegate current].currentMainViewController.tableView reloadData];
    
    [YTModelHelper save];
}

- (void)loadGPPFriends:(NSArray*)friends
{
    [YTModelHelper clearContactsWithType:@"gpp"];

    NSMutableArray *myFriends = [NSMutableArray new];

    for (NSDictionary *friend in friends) {
        NSString *name = friend[@"displayName"];
        NSMutableArray *comp = [NSMutableArray arrayWithArray:[name componentsSeparatedByString:@" "]];
        NSString *first;
        NSString *last;

        if (comp.count == 1) {
            last = name;
            first = @"";
        } else {
            last = [comp lastObject];
            [comp removeLastObject];
            first = [comp componentsJoinedByString:@" "];
        }

        NSDictionary *data = @{
            @"name": name,
            @"first_name": first,
            @"last_name": last,
            @"type": @"gpp",
            @"title": NSLocalizedString(@"Google+", nil),
            @"value": friend[@"id"],
        };
        
        [myFriends addObject:@{@"type": @"gpp", @"value": friend[@"id"], @"name": name}];

        [YTModelHelper addContactWithData:data];
    };
    
    [self addRandomizedFriends:myFriends];
    
    [YTModelHelper save];
}

- (NSArray*)findContactsWithString:(NSString*)string grouped:(BOOL)grouped
{
    NSMutableArray *categories = [NSMutableArray new];
    NSMutableArray *category = nil;
    NSMutableArray *group = nil;
    NSString *prevName = nil;
    NSArray *objects = [YTModelHelper findContactsWithString:string];
    NSMutableArray *matchedNameCategory = [[NSMutableArray alloc] initWithObjects:@" ", [NSMutableArray new], nil];
    
    for (NSManagedObject* object in objects) {
        NSDictionary *dict = [object dictionaryWithValuesForKeys:[[[object entity] attributesByName] allKeys]];
        NSString *name = [dict[@"name"] lowercaseString];
        NSString *key;
        
        if ([dict[@"last_name"] length] == 0 && [dict[@"first_name"] length] == 0) {
            key = @" ";
        } else if ([dict[@"last_name"] length] > 0) {
            key = [[dict[@"last_name"] substringToIndex:1] uppercaseString];
        } else {
            key = [[dict[@"first_name"] substringToIndex:1] uppercaseString];
        }
        
        if ([name hasPrefix:[string lowercaseString]]) {
            
            group = [NSMutableArray new];
            [matchedNameCategory[1] addObject:group];
            
        } else {
        
            if (category == nil || ![key isEqualToString:category[0]]) {
                category = [[NSMutableArray alloc] initWithObjects:key, [NSMutableArray new], nil];
                [categories addObject:category];
            }
        
            if (prevName == nil || ![prevName isEqualToString:name] || !grouped) {
                group = [NSMutableArray new];
                [category[1] addObject:group];
            }
            
        }
        
        [group addObject:dict];
        prevName = name;
    };
    
    if ([matchedNameCategory[1] count] > 0) {
        [categories insertObject:matchedNameCategory atIndex:0];
    }
    
    return categories;    
}

- (NSArray *)findContactsFlatWithString:(NSString*)string
{
    NSMutableArray *ret = [NSMutableArray new];
    NSArray *objects = [YTModelHelper findContactsWithString:string];
    
    for (NSManagedObject *object in objects) {
        NSDictionary *contact = [object dictionaryWithValuesForKeys:object.entity.attributesByName.allKeys];
        [ret addObject:contact];
    }

    return ret;
}

- (NSDictionary*)findContactWithType:(NSString*)type value:(NSString*)value
{
    NSManagedObject *object = [YTModelHelper findContactWithType:type value:value];
    if (object) {
        return [object dictionaryWithValuesForKeys:[[[object entity] attributesByName] allKeys]];
    } else {
        return nil;
    }
}

- (void)showAvatarInImageView:(UIImageView *)imageView forContact:(NSDictionary*)contact
{
    if ([contact[@"type"] isEqualToString:@"facebook"]) {
        NSString *urls = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", contact[@"value"]];
        [imageView setImageWithURL:[NSURL URLWithString:urls] placeholderImage:[YTHelper imageNamed:@"avatar6"] options:SDWebImageRefreshCached];
    } else if ([contact[@"type"] isEqualToString:@"gpp"]) {
        NSString *urls = [NSString stringWithFormat:@"https://profiles.google.com/s2/photos/profile/%@?sz=50", contact[@"value"]];
        [imageView setImageWithURL:[NSURL URLWithString:urls] placeholderImage:[YTHelper imageNamed:@"avatar6"] options:SDWebImageRefreshCached];
    } else {
        [imageView setImage:nil];
    }
}

@end
