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

@interface ActiveEventMapViewController ()
{
    GMSMapView *_mapView;
    GMSCoordinateBounds *_bounds;
    NSDictionary *_userLocations;
    CLLocationCoordinate2D _venueLocation;
}

@property (strong, nonatomic) NSMutableSet *friendIDs;

@end

@implementation ActiveEventMapViewController

- (id) initWithGuests:(NSMutableSet *)attendingFriends userLocations: (NSDictionary *) userLocations venueLocation:(CLLocationCoordinate2D) venueLocation
{
    self = [super init];
    if (self) {
        _friendIDs = attendingFriends;
        _userLocations = userLocations;
        _venueLocation = venueLocation;
    }
    return self;
}

- (void) loadView
{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_venueLocation.latitude longitude:_venueLocation.longitude zoom:14];
                                 
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    
    _mapView.myLocationEnabled = YES;
    
    GMSMarker *venueMarker=[GMSMarker markerWithPosition:_venueLocation];
    
    
                          
    venueMarker.map=_mapView;
    venueMarker.icon=[GMSMarker markerImageWithColor:[UIColor purpleColor]];
    
    GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:_bounds
                                             withPadding:50.0f];
  
    
    
    [_mapView moveCamera:update];
    self.view = _mapView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}



- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    for(NSString *key in _userLocations){
        
        PFGeoPoint *location = _userLocations[key];
        
        CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(location.latitude, location.longitude);
        
        GMSMarker *marker=[GMSMarker markerWithPosition:coordinates];
        
        _bounds= [_bounds includingCoordinate:coordinates];
        GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:_bounds
                                                 withPadding:50.0f];
        
        
        [_mapView moveCamera:update];
        marker.map=_mapView;
        
    }

    /*
    [[ParseDataStore sharedStore]fetchLocationDataWithCompletion:^(NSArray *array){
        if(array.count > 0)
        {
            for(PFGeoPoint *obj in array){
            GMSMarker *marker=[GMSMarker markerWithPosition:CLLocationCoordinate2DMake(obj.latitude, obj.longitude)];
            
            _bounds= [_bounds includingCoordinate:CLLocationCoordinate2DMake(obj.latitude, obj.longitude)];
            GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:_bounds
                                                     withPadding:50.0f];
            
            
            [_mapView moveCamera:update];
            marker.map=_mapView;
            
            }
        }
            
        else if (array.count == 0){
            GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_venueLocationCoordinate.latitude longitude:_venueLocationCoordinate.longitude zoom:14];
        _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
        
        }
    }
    
     ];*/
}

@end
