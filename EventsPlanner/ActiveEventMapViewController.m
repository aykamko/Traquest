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
}

@property (strong, nonatomic) FBEventDetailsViewController *detailsViewController;
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

- (void)loadView
{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:37.4842
                                                            longitude:-122.1485
                                                                 zoom:14];
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    
    _mapView.myLocationEnabled = YES;
    _bounds=[[GMSCoordinateBounds alloc]initWithCoordinate:CLLocationCoordinate2DMake(37.4842, -122.1485) coordinate:CLLocationCoordinate2DMake(37.7, -122.16)];
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
