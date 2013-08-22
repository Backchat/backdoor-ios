//
//  YTGabs.m
//  Backdoor
//
//  Created by Lin Xu on 8/19/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTGabs.h"
#import "YTAppDelegate.h"
#import "YTApiHelper.h"
#import <Flurry.h>
#import <Mixpanel.h>

@interface YTGabs ()
{
}
@property (nonatomic, retain) NSFetchRequest* request;
@property (nonatomic, retain) NSArray* items;
@end

@implementation YTGabs
- (id) initWithSearchString:(NSString *)string
{
    if(self = [super init]) {
        self.request = [[NSFetchRequest alloc] initWithEntityName:@"Gabs"];
        NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
        
        if (string && ![string isEqualToString:@""]) {
            self.request.predicate = [NSPredicate predicateWithFormat:@"(total_count > 0) && (content_cache LIKE[cd] %@ || related_user_name LIKE[cd] %@)", string, string];
        }
        else {            
            self.request.predicate = [NSPredicate predicateWithFormat:@"(total_count > 0)"];
        }
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updated_at" ascending:NO];
        self.request.sortDescriptors = @[sortDescriptor];
        
        NSError *error;
        self.items = [context executeFetchRequest:self.request error:&error];
    }
    return self;
}

- (id) init
{
    return [self initWithSearchString:@""];
}

- (YTGab*) gabAtIndex:(int)index
{
    return [self.items objectAtIndex:index];
}

- (int) count
{
    return self.items.count;
}

+ (int) totalGabCount
{
    NSManagedObjectContext *context = [YTAppDelegate current].managedObjectContext;
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:@"Gabs"];
    request.predicate = [NSPredicate predicateWithFormat:@"(total_count > 0)"];
    NSError *error;
    return [context countForFetchRequest:request error:&error];
}

+ (void)updateGabs
{
    [YTApiHelper sendJSONRequestToPath:@"/gabs" method:@"GET" params:nil
                                success:^(id JSON) {
                                    id gabs = JSON[@"gabs"];
                                    for (NSDictionary *u in gabs) {
                                        [YTGab updateGab:u];
                                    }
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:YTGabsUpdatedNotification
                                                                                        object:nil];
                                }
                                failure:nil];
}

+ (void) deleteGab:(YTGab *)gab
{
    gab.total_count = @0;
        
    [[NSNotificationCenter defaultCenter] postNotificationName:YTGabsUpdatedNotification object:nil];
    
    if(![gab isFakeGab]) {
        [YTApiHelper sendJSONRequestToPath:[NSString stringWithFormat:@"/gabs/%@", gab.id]
                                    method:@"DELETE" params:nil success:nil failure:nil];
            
        [Flurry logEvent:@"Deleted_Thread"];
        [[Mixpanel sharedInstance] track:@"Deleted Thread"];
    }
}


@end

NSString* const YTGabsUpdatedNotification = @"YTGabsUpdatedNotification";