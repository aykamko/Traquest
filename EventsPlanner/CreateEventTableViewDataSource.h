//
//  NewEventTableViewDataSource.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/9/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CreateEventModel.h"
@class CreateEventTimePickerViewController;
@class CreateEventPrivacyViewController;

@interface CreateEventTableViewDataSource : NSObject <UITableViewDataSource>

- (id)initWithEventModel:(CreateEventModel *)createEventModel existingEvent:(BOOL)existingEvent;

@property (strong, nonatomic, readonly) CreateEventTimePickerViewController *timePickerViewController;
@property (strong, nonatomic, readonly) CreateEventPrivacyViewController *privacyViewController;

@end
