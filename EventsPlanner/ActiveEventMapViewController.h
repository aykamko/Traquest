//
//  ActiveEventMapViewController.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <MapKit/MapKit.h>

@interface ActiveEventMapViewController : UIViewController<CLLocationManagerDelegate, MKMapViewDelegate>

@property (strong, nonatomic) NSMutableDictionary *friendAnnotationPointDict;
@property (strong, nonatomic) NSMutableDictionary *anonAnnotationPointDict;

- (id)initWithEventId:(NSString *)eventId venueLocation:(CLLocationCoordinate2D) venueLocation;
- (void)updateMarkersOnMapWithAllowedGuests: (NSDictionary *) allowedLocations withAnonGuests: (NSDictionary *) anonLocations;

@end
