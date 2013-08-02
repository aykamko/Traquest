//
//  ActiveEventMapViewController.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import "ActiveEventMapViewController.h"
#import "FBEventDetailsViewController.h"

@interface ActiveEventMapViewController ()
{
    GMSMapView *_mapView;
}

@property (strong, nonatomic) FBEventDetailsViewController *guestDetailsViewController;
@end

@implementation ActiveEventMapViewController

- (id) initWithFriendsDetails:(NSMutableArray *)attendingFriends
{
    self = [super init];
    if (self) {
        _friendsIDArray = attendingFriends;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:37.4842
                                                            longitude:-122.1485
                                                                 zoom:14];
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    _mapView.myLocationEnabled = YES;
    self.view = _mapView;
}


// method has been moved from FBHostEventDetailsViewController
- (void) viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    PFQuery *query = [PFUser query];
    [query whereKey:@"fbID" containedIn:_friendsIDArray];
    [query findObjectsInBackgroundWithBlock:^(NSArray *array, NSError *error) {
        for (int i = 0; i < [array count]; i++)
        {
            PFGeoPoint *geoPoint = [[array objectAtIndex:i] objectForKey:@"location"];
            CLLocationCoordinate2D guestLocation = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
            
            GMSMarker *add_annotation = [GMSMarker markerWithPosition:guestLocation];
            add_annotation.map = _mapView;
        }
    }];
}


@end
