//
//  EventsTableViewDataSource.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EventsTableViewDataSource : NSObject<UITableViewDataSource>

@property (nonatomic, strong) NSArray *eventArray;
@property (nonatomic, strong) NSMutableArray *activeEvents;
@property (nonatomic, strong) NSMutableArray *inactiveEvents;

- (id)initWithEventArray:(NSArray *)eventArray;

@end
