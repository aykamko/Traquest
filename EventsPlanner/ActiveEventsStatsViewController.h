//
//  ActiveEventsStatsViewController.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <MapKit/MapKit.h>

@interface ActiveEventsStatsViewController : UITableViewController<UITableViewDelegate>

@property NSArray *statistics;
@property NSArray *statisticsKeys;

-(id)initWithEventId:(NSString *)eventId venueLocation:(CLLocationCoordinate2D)venueLocation;
- (void) updateStatistics;

@end
