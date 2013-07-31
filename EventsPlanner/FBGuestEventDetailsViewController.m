//
//  FBEventDetailsViewController.m
//  EventsPlanner
//
//  Created by Ashwin Murthy on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import "FBGuestEventDetailsViewController.h"
#import "MapPoint.h"
#import "MKGeocodingService.h"

@interface FBGuestEventDetailsViewController ()
{
    __weak IBOutlet UIView *_mapViewPlaceholder;
    __strong GMSMapView *_mapView;
    NSDictionary *_eventDetails;
}

- (void)moveMapCameraAndPlaceMarkerAtCoordinate:(CLLocationCoordinate2D)coordinate;

@end

@implementation FBGuestEventDetailsViewController

- (id)initWithEventDetails:(NSDictionary *)details
{
    self = [super init];
    if (self) {
        _eventDetails = details;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *eventTitle = [_eventDetails objectForKey:@"name"];
    
    [_titleLabel setText:eventTitle];
    
    CGFloat fontSize = MIN(24,625/[eventTitle length]);
    
    UIFont *font = [UIFont fontWithName:[[_titleLabel font] fontName] size:fontSize];
    
    [_titleLabel setFont:font];
    
    self.navBar = self.navigationController.navigationBar;
    
    
    NSString *locationName = [_eventDetails objectForKey:@"location"];
    NSDictionary *venueDict = [_eventDetails objectForKey:@"venue"];
    
    [_addressLabel setText:locationName];
    [_addressLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
    
    if (venueDict[@"latitude"]) {
        
        NSString *latString = venueDict[@"latitude"];
        NSString *lngString = venueDict[@"longitude"];
        double latitude = [latString doubleValue];
        double longitude = [lngString doubleValue];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        
        CLLocationCoordinate2D eventLocation = CLLocationCoordinate2DMake(latitude, longitude);
        MapPoint *add_Annotation = [[MapPoint alloc] initWithCoordinate:eventLocation title:@"myTitle"];
        //[_eventMapView addAnnotation:add_Annotation];
       // NSLog(@"%f,%f",latitude,longitude);
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(eventLocation, 5000, 2500);
        //[_eventMapView setRegion:region animated:NO];
        [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
        
    } else {
        
        MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
        
        [geocoder fetchGeocodeAddress:locationName completion:^(NSDictionary *geocode, NSError *error) {
            CLLocationCoordinate2D coordinate = [((CLLocation *)geocode[@"location"]) coordinate];
            [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
        }];
        
    }

}

- (void)viewDidAppear:(BOOL)animated
{
    NSNumber *tracking = [[PFUser currentUser] objectForKey:@"trackingAllowed"];
    if ([tracking isEqualToNumber:@0])
    {
        
        UIAlertView *requestTracking = [[UIAlertView alloc] initWithTitle:@"Hi!" message:@"Allow the host to see where you are" delegate:nil cancelButtonTitle: @"YES" otherButtonTitles:@"Anonymous",@"NO",nil];
        requestTracking.cancelButtonIndex = -1;
        [requestTracking show];
       
    }
    else
    {
        /*
        PFGeoPoint *guestLocation = [[PFUser currentUser] objectForKey:@"location"];
        CLLocationCoordinate2D guestCoordinate = CLLocationCoordinate2DMake(guestLocation.latitude, guestLocation.longitude);
        MapPoint *add_Annotation = [[MapPoint alloc] initWithCoordinate: guestCoordinate title:@"guestTitle"];
        //NSLog(@"Greetings, %f,%f",guestCoordinate.latitude,guestCoordinate.longitude);
    
        [_eventMapView addAnnotation:add_Annotation];
         */
    }
}

- (void)moveMapCameraAndPlaceMarkerAtCoordinate:(CLLocationCoordinate2D)coordinate
{
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude
                                                                longitude:coordinate.longitude
                                                                     zoom:14];
        _mapView = [GMSMapView mapWithFrame:[_mapViewPlaceholder frame] camera:camera];
        _mapView.myLocationEnabled = YES;
    
        GMSMarker *marker = [[GMSMarker alloc] init];
        marker.position = coordinate;
        marker.map = _mapView;
        
        [_mapViewPlaceholder removeFromSuperview];
        [self.view addSubview:_mapView];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((buttonIndex == 0) || (buttonIndex == 1))
    {
            [[PFUser currentUser] setObject:[NSNumber numberWithBool:YES] forKey:@"trackingAllowed"];
    }
    else
    {
       // NSLog(@"User didn't enable Event Tracker!");
    }
}
@end