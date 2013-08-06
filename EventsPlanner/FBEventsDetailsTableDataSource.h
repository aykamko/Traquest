//
//  FBGuestEventsDetailsDataSource.h
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBEventsDetailsTableDataSource : NSObject <UITableViewDataSource>

- initWithEventDetails: (NSDictionary*) eventDetails;
- (void) updateObject: (NSString *) value forKey: (NSString *) key;

@end
