//
//  ActiveEventMapViewController.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ActiveEventMapViewController : UIViewController


- (id) initWithGuestDetails:(NSMutableDictionary *)details venueLocation:(CLLocationCoordinate2D) venueLocation;

@end
