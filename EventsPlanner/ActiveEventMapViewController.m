//
//  ActiveEventMapViewController.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import "ActiveEventMapViewController.h"

@interface ActiveEventMapViewController ()
{
    GMSMapView *_mapView;
}

@property (strong, nonatomic) FBHostEventDetailsViewController *hostDetailsViewController;
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
    [_navBar pushNavigationItem:self.navigationItem animated:YES];
    [_mapView addSubview:_navBar];
}

- (void) back
{
    _hostDetailsViewController = [[FBHostEventDetailsViewController alloc] init];
    [[self navigationController] pushViewController: _hostDetailsViewController animated:YES];
}

- (void) loadView
{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:37.4842
                                                            longitude:-122.1485
                                                                 zoom:14];
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    _mapView.myLocationEnabled = YES;
    self.view = _mapView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
