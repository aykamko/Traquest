//
//  FBGuestEventsDetailsDataSource.h
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBEventDetailsTableDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, readonly) NSArray *orderedDetailsKeys;
@property (nonatomic, readonly) NSDictionary *detailsDict;

- initWithEventDetails:(NSDictionary*) eventDetails;
- (void)updateObject:(NSString *)value forKey:(NSString *)key;

@end
