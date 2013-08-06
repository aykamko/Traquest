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
#import "ParseDataStore.h"

@interface ActiveEventMapViewController (){
    
    GMSMapView *_mapView;
    GMSCoordinateBounds *_bounds;
    
    CLLocationCoordinate2D _venueLocation;
    NSMutableDictionary *_guestDetails;
}

@property (strong, nonatomic) NSMutableSet *friendIDs;

@end

@implementation ActiveEventMapViewController

- (id) initWithGuestDetails:(NSMutableDictionary *)details venueLocation:(CLLocationCoordinate2D) venueLocation
{
    self = [super init];
    if (self) {
        _guestDetails = details;
        _venueLocation = venueLocation;
        _bounds=[[GMSCoordinateBounds alloc]initWithCoordinate:_venueLocation coordinate:_venueLocation];

    }
    return self;
}


- (void) loadView
{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_venueLocation.latitude longitude:_venueLocation.longitude zoom:14];
                                 
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    
    _mapView.myLocationEnabled = YES;
    
    GMSMarker *venueMarker=[GMSMarker markerWithPosition:_venueLocation];
    
    venueMarker.title=@"Venue Location";
    NSLog(@"%@ asd fjdasjf halkdsjh ", _guestDetails);
                          
    venueMarker.map=_mapView;
    venueMarker.icon=[GMSMarker markerImageWithColor:[UIColor purpleColor]];
    
    GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:_bounds
                                             withPadding:50.0f];

    [_mapView moveCamera:update];
    self.view = _mapView;
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    [self.navigationController setNavigationBarHidden:NO animated:animated];
//    [super viewWillAppear:animated];
//}



- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    for(NSString *key in _guestDetails){
    
        NSDictionary *userDetails = _guestDetails[key];
        
        
        PFGeoPoint *location = userDetails[@"location"];
        
        if(fabs(location.longitude)>0 & fabs(location.longitude)>0){
        
        GMSMarker *marker= [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(location.latitude, location.longitude)];
        marker.title=userDetails[@"name"];
        marker.map=_mapView;

        _bounds= [_bounds includingCoordinate:CLLocationCoordinate2DMake(location.latitude, location.longitude)];
       
        GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:_bounds
                                                 withPadding:50.0f];
           GMSCameraUpdate *update2=[GMSCameraUpdate zoomOut];
        [_mapView moveCamera:update];
            [_mapView moveCamera:update2];
        }
    }

}

@end
