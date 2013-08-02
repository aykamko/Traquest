//
//  FBHostEventDetailsViewController.m
//  EventsPlanner
//
//  Created by Anupa Murali on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBHostEventDetailsViewController.h"
#import "MKGeocodingService.h"

@interface FBHostEventDetailsViewController ()
{
    __weak IBOutlet UIView *_mapViewPlaceholder;
    __strong GMSMapView *_mapView;
    NSDictionary *_eventDetails;
    ActiveEventMapViewController *_mapViewController;
}

- (IBAction)_temp_openMapView:(id)sender;
- (void)moveMapCameraAndPlaceMarkerAtCoordinate:(CLLocationCoordinate2D)coordinate;

@property (nonatomic, strong) ActiveEventMapViewController *temp_mapView;
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

- (void)_temp_openMapView:(id)sender
{
    _temp_mapView = [[ActiveEventMapViewController alloc] init];
    [self.navigationController pushViewController:_temp_mapView
                                         animated:YES];
}

// much of this can be commented out... not that useful. Please remember to eventually get rid of everything that
// is related to MapPoint, as we are now implementing everything using Google Maps
- (void)viewWillAppear:(BOOL)animated
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    NSString *locationAddress = [_eventDetails objectForKey:@"location"];
    
    [geocoder geocodeAddressString:locationAddress completionHandler:^(NSArray* placemarks, NSError* error){
        
        CLPlacemark *aPlacemark = [placemarks firstObject];
        double latitude = aPlacemark.location.coordinate.latitude;
        double longitude = aPlacemark.location.coordinate.longitude;
        
        CLLocationCoordinate2D eventLocation = CLLocationCoordinate2DMake(latitude, longitude);
        GMSMarker *add_Annotation = [GMSMarker markerWithPosition:eventLocation];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    [self initFriendsIDArray];
}

// The following method populates friendIDArray with the
// Facebook ID's of the friends who will attend the event.
- (void)initFriendsIDArray
{
    FBGraphObject *fbGraphObj = (FBGraphObject *)_eventDetails;
    NSArray *attendingFriends = fbGraphObj[@"attending"][@"data"];
    
    _friendsIDArray = [[NSMutableArray alloc] init];
    
    // Populate friendsIDArray with the ID's of
    // everyone attending event
    for (NSDictionary *friend in attendingFriends)
    {
        [_friendsIDArray addObject:(NSString *)friend[@"id"]];
        NSLog((NSString *)friend[@"id"]);
    }

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
        
        [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
        
    } else {
        
        MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
        
        [geocoder fetchGeocodeAddress:locationName completion:^(NSDictionary *geocode, NSError *error) {
            CLLocationCoordinate2D coordinate = [((CLLocation *)geocode[@"location"]) coordinate];
            [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
        }];
        
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((buttonIndex == 0)||(buttonIndex == 1))
    {
        [[PFUser currentUser] setObject:[NSNumber numberWithBool:YES]  forKey:@"trackingAllowed"];
    }
    else
    {
        NSLog(@"User didn't enable Event Tracker!");
    }
}

-(IBAction)loadMapView:(id)sender
{
    _mapViewController = [[ActiveEventMapViewController alloc] init];
    [_mapViewController initWithFriendsDetails:_friendsIDArray];
    [[self navigationController] pushViewController: _mapViewController animated:YES];
}



@end
