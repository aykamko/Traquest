//
//  FBGuestEventsDetailsDataSource.h
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBGuestEventsDetailsDataSource : NSObject <UITableViewDataSource>

-initWithEventDetails: (NSDictionary*) eventDetails;

@end
