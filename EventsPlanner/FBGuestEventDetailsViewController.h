//
//  FBEventDetailsViewController.h
//  EventsPlanner
//
//  Created by Ashwin Murthy on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

@interface FBGuestEventDetailsViewController : UIViewController <MKMapViewDelegate,CLLocationManagerDelegate>

- (id)initWithEventDetails:(NSDictionary *)details;

@property (strong, nonatomic) IBOutlet MKMapView *eventMapView;

@end
