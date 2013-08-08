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
#import "Toast+UIView.h"

@interface ActiveEventMapViewController (){
    
    GMSMapView *_mapView;
    GMSCoordinateBounds *_bounds;
    
    CLLocationCoordinate2D _venueLocation;
    NSMutableDictionary *_guestDetails;
    UISegmentedControl *_segment;
}

@property (strong, nonatomic) NSMutableDictionary *friendDetailsDict;
@property (strong, nonatomic) NSMutableDictionary *friendMarkerDict;

@property (strong, nonatomic) UIView *toastSpinner;

@end

@implementation ActiveEventMapViewController

- (id)initWithGuestArray:(NSArray *)guestArray eventId:(NSString *)eventId venueLocation:(CLLocationCoordinate2D)venueLocation
{
    self = [super init];
    if (self) {
        UITabBarItem *icon = [self tabBarItem];
        UIImage *image= [UIImage imageNamed:@"MarkerFinal.png"];
        [icon setImage:image];
        
        _venueLocation = venueLocation;
        _friendMarkerDict = [[NSMutableDictionary alloc] init];
        
        _friendDetailsDict = [[NSMutableDictionary alloc] init];
        for (FBGraphObject *user in guestArray) {
            UIImage *userPic = [[UIImage alloc]initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:user[@"picture"][@"data"][@"url"]]]];
            NSMutableDictionary *friendDetailsSubDict = [[NSMutableDictionary alloc]
                                                         initWithDictionary:@{ @"geopoint":[NSNull null],
                                                                               @"name":user[@"name"],
                                                                               @"userPic":userPic }];

            [[self friendDetailsDict] addEntriesFromDictionary:@{ user[@"id"]:friendDetailsSubDict }];
        }
        
        [[ParseDataStore sharedStore] fetchGeopointsForIds:[[self friendDetailsDict] allKeys] eventId:eventId
                                                completion:^(NSDictionary *userLocations) {
            for (NSString *fbId in [userLocations allKeys]) {
                [self friendDetailsDict][fbId][@"geopoint"] = userLocations[fbId];
            }
            [self updateMarkersOnMap];
        }];
        
        
    }
    
    
    return self;
}

- (void)loadView
{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_venueLocation.latitude
                                                            longitude:_venueLocation.longitude
                                                                 zoom:14];
                                 
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    _mapView.myLocationEnabled = YES;
    
    GMSMarker *venueMarker = [GMSMarker markerWithPosition:_venueLocation];
    
    venueMarker.title = @"Venue Location";
    venueMarker.map = _mapView;
    venueMarker.icon = [GMSMarker markerImageWithColor:[UIColor purpleColor]];
    
    _bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:_venueLocation coordinate:_venueLocation];
    
    GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:_bounds withPadding:50.0f];

    [_mapView moveCamera:update];
    self.view = _mapView;
    
    [self.view makeToastActivity];

    
   
}

- (void)updateMarkersOnMap
{
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:_venueLocation
                                                                       coordinate:_venueLocation];
    for (NSString *fbId in [[self friendDetailsDict] allKeys]) {
        
        PFGeoPoint *currentGeopoint = self.friendDetailsDict[fbId][@"geopoint"];
        if ([currentGeopoint isEqual:[NSNull null]]) {
            continue;
        }
        
        CLLocationCoordinate2D currentCoordinate = CLLocationCoordinate2DMake(currentGeopoint.latitude,
                                                                              currentGeopoint.longitude);
        
        NSString *currentName = self.friendDetailsDict[fbId][@"name"];
        GMSMarker *currentMarker = self.friendMarkerDict[fbId];
    
        
        if (!currentMarker) {
            
            currentMarker = [GMSMarker markerWithPosition:currentCoordinate];
            currentMarker.icon= self.friendDetailsDict[fbId][@"userPic"];
            currentMarker.title = currentName;
            currentMarker.map = _mapView;
            self.friendMarkerDict[fbId] = currentMarker;
            
        } else {
            
            currentMarker.position = currentCoordinate;
            
        }
        
        bounds = [bounds includingCoordinate:currentCoordinate];
    }
    
    [self.view hideToastActivity];
    [_mapView moveCamera:[GMSCameraUpdate fitBounds:bounds withPadding:100.0f]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"BERTERM ERF SCRERN %@", NSStringFromCGRect(self.view.frame));
    NSLog(@"center: %f", self.view.center.x );
    


}


-(void)viewDidLoad{
    [super viewDidLoad];

    

}
@end
