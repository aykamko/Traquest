//
//  FBDataStore.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBDataStore : NSObject

+ (FBDataStore *)sharedStore;

- (void)fetchEventListDataWithCompletion:(void (^)(NSArray *eventData))completionBlock;

@end
