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



- (id)initWithGuestArray:(NSArray *)guestArray eventId:(NSString *)eventId venueLocation:(CLLocationCoordinate2D)venueLocation;


@end
