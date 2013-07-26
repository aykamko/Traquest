//
//  EventsTableViewDataSource.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EventsTableViewDataSource : NSObject<UITableViewDataSource>

-(id)initWithHostEvent:hostEvents guestEvents:guestEvents;

@end
