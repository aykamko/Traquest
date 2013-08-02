//
//  FBHostEventDetailsViewController.m
//  EventsPlanner
//
//  Created by Anupa Murali on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBHostEventDetailsViewController.h"
#import "MapPoint.h"

@interface FBHostEventDetailsViewController ()
{

    NSDictionary *_eventDetails;
}
@end

@implementation FBHostEventDetailsViewController

- (id)initWithHostEventDetails:(NSDictionary *)details
{
    self = [super init];
    if (self) {
        _eventDetails = details;
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated
{    
    NSString *locationAddress = [_eventDetails objectForKey:@"location"];
    
    FBGraphObject *fbGraphObj = (FBGraphObject *)_eventDetails;
    NSArray *allFriends = fbGraphObj[@"attending"][@"data"];
    
    _friendsArray = [[NSMutableArray alloc] init];
    for (NSDictionary *friend in allFriends)
    {
        [_friendsArray addObject:(NSString *)friend[@"id"]];

    }
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:locationAddress completionHandler:^(NSArray* placemarks, NSError* error){
        
        CLPlacemark *aPlacemark = [placemarks firstObject];
        double latitude = aPlacemark.location.coordinate.latitude;
        double longitude = aPlacemark.location.coordinate.longitude;
        
        CLLocationCoordinate2D eventLocation = CLLocationCoordinate2DMake(latitude, longitude);
        MapPoint *add_Annotation = [[MapPoint alloc] initWithCoordinate:eventLocation title:@"myTitle"];
   //     [_eventMapView addAnnotation:add_Annotation];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(eventLocation, 1000000, 1000000);
        [_eventMapView setRegion:region animated:NO];
        
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    PFQuery *query = [PFUser query];
    [query whereKey:@"fbID" containedIn:_friendsArray];
    [query whereKeyExists:@"location"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *array, NSError *error) {
        for (int i = 0; i < [array count]; i++)
        {
            PFGeoPoint *geoPoint = [[array objectAtIndex:i] objectForKey:@"location"];
            CLLocationCoordinate2D guestLocation = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
            MapPoint *add_point = [[MapPoint alloc] initWithCoordinate:guestLocation title:@"newTitle"];
            [_eventMapView addAnnotation:add_point];
        }
    }];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((buttonIndex == 0)||(buttonIndex == 1))
    {
        [[PFUser currentUser] setObject:[NSNumber numberWithBool:YES]  forKey:@"trackingAllowed"];
    }

}

@end
