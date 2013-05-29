//
//  YTStoreHelper.h
//  YouTellMobile
//
//  Copyright (c) 2013 Backdoor LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface YTStoreHelper : NSObject <SKProductsRequestDelegate, UIActionSheetDelegate, SKPaymentTransactionObserver>

@property (strong, nonatomic) SKProductsRequest *productsRequest;
@property (weak, nonatomic) UIBarButtonItem *barButtonItem;
@property (strong, nonatomic) NSMutableDictionary *products;


- (void)showFromBarButtonItem:(UIBarButtonItem*)barButtonItem;

@end
