//
//  Database.h
//  SmartReceipts
//
//  Created by Jaanus Siim on 28/04/15.
//  Copyright (c) 2015 Will Baumann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"

@class ReceiptFilesManager;

extern NSString *const DatabaseDidInsertModelNotification;
extern NSString *const DatabaseDidDeleteModelNotification;
extern NSString *const DatabaseDidUpdateModelNotification;

@interface Database : NSObject

@property (nonatomic, strong, readonly) FMDatabaseQueue *databaseQueue;
@property (nonatomic, strong, readonly) ReceiptFilesManager *filesManager;

+ (instancetype)sharedInstance;

- (BOOL)open;
- (void)close;

@end
