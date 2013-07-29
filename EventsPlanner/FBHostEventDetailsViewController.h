//
//  FBHostEventDetailsViewController.h
//  EventsPlanner
//
//  Created by Anupa Murali on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import "LoginViewController.h"

@interface FBHostEventDetailsViewController : UIViewController <MKMapViewDelegate,CLLocationManagerDelegate>

- (id)initWithHostEventDetails:(NSDictionary *)details;

@property (strong, nonatomic) IBOutlet MKMapView *eventMapView;

@property (strong, nonatomic) NSMutableArray *friendsArray;

@property BOOL startTracking;

@end
