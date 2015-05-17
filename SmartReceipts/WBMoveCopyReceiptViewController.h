//
//  WBMoveCopyReceiptViewController.h
//  SmartReceipts
//
//  Created on 01/04/14.
//  Copyright (c) 2014 Will Baumann. All rights reserved.
//

#import "WBTableViewController.h"

#import "WBReceiptActionsViewController.h"
#import "WBReceiptsViewController.h"
#import "TripsViewController.h"

@interface WBMoveCopyReceiptViewController : FetchedCollectionTableViewController

@property (nonatomic, assign) BOOL calledForCopy;
@property (nonatomic, strong) WBReceipt *receipt;

@end
