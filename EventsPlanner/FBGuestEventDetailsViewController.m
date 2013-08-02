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
#import "ActiveEventMapViewController.h"
#import <GoogleMaps/GoogleMaps.h>


@interface FBGuestEventDetailsViewController ()
{
    __weak IBOutlet UIView *_mapViewPlaceholder;
    __strong GMSMapView *_mapView;
    NSDictionary *_eventDetails;
    CLLocationDistance longestDistance;
    CLLocationCoordinate2D farthestCoordinate;
    CLLocationCoordinate2D venueCoordinate;
    CLLocation *_venueLocation;
    NSMutableArray *_locationArray;
    GMSCoordinateBounds *_bounds;
    

}

- (IBAction)_temp_openMapView:(id)sender;
- (void)moveMapCameraAndPlaceMarkerAtCoordinate:(CLLocationCoordinate2D)coordinate;

@property (nonatomic, strong) ActiveEventMapViewController *temp_mapView;
@end

@implementation FBGuestEventDetailsViewController

- (id)initWithGuestEventDetails:(NSDictionary *)details
{
    self = [super init];
    if (self) {
        _eventDetails = details;
        longestDistance=0;
    }
    return self;
}

- (void)_temp_openMapView:(id)sender
{
    _temp_mapView = [[ActiveEventMapViewController alloc] init];
    [self.navigationController pushViewController:_temp_mapView
                                         animated:YES];

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
    NSLog(@"location name: %@", locationName);
    [_addressLabel setText:locationName];
    [_addressLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
    
    if (venueDict[@"latitude"]) {
        NSString *latString = venueDict[@"latitude"];
        NSString *lngString = venueDict[@"longitude"];
        double latitude = [latString doubleValue];
        double longitude = [lngString doubleValue];
        venueCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
        _venueLocation=[[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
        
        NSLog(@" venue coordinate: (long, lat) ( %f, %f )", venueCoordinate.longitude, venueCoordinate.latitude);
        
        
        
        [self moveMapCameraAndPlaceMarkerAtCoordinate:venueCoordinate];
        farthestCoordinate=venueCoordinate;

        [self checkDistance];
  
    } else {
        
        MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
        
        [geocoder fetchGeocodeAddress:locationName completion:^(NSDictionary *geocode, NSError *error) {
            venueCoordinate = [((CLLocation *)geocode[@"location"]) coordinate];
            _venueLocation=[[CLLocation alloc]initWithLatitude:venueCoordinate.latitude longitude:venueCoordinate.longitude];
            farthestCoordinate=venueCoordinate;

            [self moveMapCameraAndPlaceMarkerAtCoordinate:venueCoordinate];
            [self checkDistance];

        }];


    }
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    NSNumber *tracking = [[PFUser currentUser] objectForKey:@"trackingAllowed"];
    if ([tracking isEqualToNumber:@0])
    {
        
        UIAlertView *requestTracking = [[UIAlertView alloc] initWithTitle:@"Hi!" message:@"Allow the host to see where you are" delegate:self cancelButtonTitle: @"YES" otherButtonTitles:@"Anonymous",@"NO",nil];
        requestTracking.cancelButtonIndex = -1;
        [requestTracking show];
       
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

}



-(void)checkDistance{
    
    CLLocationCoordinate2D coordinate2 = CLLocationCoordinate2DMake(venueCoordinate.latitude+0.01, venueCoordinate.longitude+0.01);
    
    CLLocationCoordinate2D coordinate3= CLLocationCoordinate2DMake(venueCoordinate.latitude-0.01, venueCoordinate.longitude-0.01);
    
    CLLocation *location2=[[CLLocation alloc]initWithLatitude:coordinate2.latitude longitude:coordinate2.longitude];
    CLLocationDistance dist2=fabs([location2 distanceFromLocation:_venueLocation]);
    
    CLLocation *location3=[[CLLocation alloc]initWithLatitude:coordinate2.latitude longitude:coordinate2.longitude];
    CLLocationDistance dist3=fabs([location3 distanceFromLocation:_venueLocation]);

   
    
    GMSMarker *marker2 = [[GMSMarker alloc] init];
    marker2.position = coordinate2;
    marker2.map = _mapView;
    
    
    GMSMarker    *marker3=[[GMSMarker alloc]init];
    marker3.position=coordinate3;
    marker3.map=_mapView;
 
    _mapView.myLocationEnabled = YES;

    

    _bounds=[[GMSCoordinateBounds alloc]initWithCoordinate:venueCoordinate coordinate:CLLocationCoordinate2DMake(coordinate2.latitude+0.005, coordinate2.longitude+0.005)];


    if(![_bounds containsCoordinate:coordinate3]) {
        _bounds = [_bounds includingCoordinate:coordinate3];

        GMSCameraUpdate *update=[GMSCameraUpdate fitBounds:_bounds withPadding:50.0f];
        [_mapView animateWithCameraUpdate:update];
    }
    
//    GMSCameraUpdate *update=[GMSCameraUpdate fitBounds:bounds withPadding:50.0f];
//[_mapView animateWithCameraUpdate:update];


}
@end