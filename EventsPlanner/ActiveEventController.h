//
//  ActiveEventsController.h
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/17/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActiveEventMapViewController.h"
#import "ActiveEventsStatsViewController.h"

<<<<<<< HEAD
@interface ActiveEventController : NSObject <UINavigationControllerDelegate>

- (id)initWithEventId:(NSString *) eventId venueLocation:(CLLocationCoordinate2D)venueLocation;
- (UITabBarController *)presentableViewController;

- (void)startTimerForUpdates:(NSNotification *)notification;
=======
@interface ActiveEventController : NSObject

- (id)initWithEventId:(NSString *) eventId venueLocation:(CLLocationCoordinate2D)venueLocation;
-(UITabBarController *) presentableViewController;
>>>>>>> Fetched data better

@end
