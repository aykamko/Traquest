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
    CLLocation *_venueLocation;
}

@end

@implementation ActiveEventMapViewController

- (id) initWithFriendsDetails:(NSMutableArray *)attendingFriends venueLocation:(CLLocation *)location
{
    self = [super init];
    if (self) {
        _friendsIDArray = attendingFriends;
    }
    return self;
}

- (void)loadView
{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[_detailsViewController venueLocation ].coordinate.latitude
                                                            longitude:[_detailsViewController venueLocation].coordinate.longitude
                                                                 zoom:14];
    
                                 
                                 
                                 
                                 
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    
    _mapView.myLocationEnabled = YES;
    
    GMSMarker *venueMarker=[GMSMarker markerWithPosition:[_detailsViewController venueLocation].coordinate];
    
    
                          
                          
                          
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
            
        
    }
    
     ];
}



@end
