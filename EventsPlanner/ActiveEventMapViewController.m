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
#import "FBIdAnnotationPoint.h"

static const NSInteger UpdateFrequencyInSeconds = 2.0;


@interface ActiveEventMapViewController ()

@property (nonatomic) BOOL zoomToFit;

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSString *eventId;
@property (nonatomic) CLLocationCoordinate2D venueLocation;
@property (strong, nonatomic) NSMutableDictionary *friendAnnotationPointDict;
@property (strong, nonatomic) NSMutableSet *anonAnnotationPointDict;

@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) UIView *toastSpinner;

@end

@implementation ActiveEventMapViewController

- (id)initWithGuestArray:(NSArray *)guestArray eventId:(NSString *)eventId venueLocation:(CLLocationCoordinate2D)venueLocation
{
    self = [super init];
    if (self) {

        _locationManager = [[CLLocationManager alloc] init];
        
        [_locationManager setDelegate: self];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];

        UITabBarItem *icon = [self tabBarItem];
        UIImage *image= [UIImage imageNamed:@"MarkerFinal.png"];
        [icon setImage:image];
        
        _venueLocation = venueLocation;
        _eventId = eventId;
        _friendAnnotationPointDict = [[NSMutableDictionary alloc] init];
        _anonAnnotationPointDict = [[NSMutableSet alloc] init];
        _guestData = [[NSMutableDictionary alloc] init];
        for (FBGraphObject *user in guestArray) {
            UIImage *userPic = [[UIImage alloc]initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:user[@"picture"][@"data"][@"url"]]]];
            NSMutableDictionary *friendDetailsSubDict = [[NSMutableDictionary alloc]
                                                         initWithDictionary:@{ @"geopoint":[NSNull null],
                                                                               @"name":user[@"name"],
                                                                               @"userPic":userPic }];

            [[self guestData] addEntriesFromDictionary:@{ user[@"id"]:friendDetailsSubDict }];
            
        }
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    
    [self.mapView setMapType:MKMapTypeStandard];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(_venueLocation, 500, 500);
    [self.mapView setRegion:region animated:YES];
    
    MKPointAnnotation *venuePin = [[MKPointAnnotation alloc] init];
    venuePin.coordinate = self.venueLocation;
    venuePin.title = @"Venue Location";
    [self.mapView addAnnotation:venuePin];
    
    self.zoomToFit = YES;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:UpdateFrequencyInSeconds
                                                  target:self
                                                selector:@selector(updateMarkersOnMap)
                                                userInfo:nil
                                                 repeats:YES];
    [self.timer fire];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark Adding Annotations and Map View
- (void)updateMarkersOnMap
{
    for (MKPointAnnotation* annot in _anonAnnotationPointDict) {
        [_mapView removeAnnotation: annot];
    }
    [[ParseDataStore sharedStore] fetchGeopointsForIds:[self.guestData allKeys] eventId:self.eventId completion:^(NSDictionary *allowedLocations, NSSet *anonLocations) {
        
        NSMutableSet *pastAnnotationIds = [NSMutableSet setWithArray:[_friendAnnotationPointDict allKeys]];
        for (NSString *fbId in [allowedLocations allKeys]) {
            [pastAnnotationIds removeObject:fbId];
            
            if ([fbId isEqualToString:[[ParseDataStore sharedStore] myId]]) {
                continue;
            }
            
            self.guestData[fbId][@"geopoint"] = allowedLocations[fbId];
            PFGeoPoint *currentGeopoint = self.guestData[fbId][@"geopoint"];
            
            CLLocationCoordinate2D currentCoordinate = CLLocationCoordinate2DMake(currentGeopoint.latitude,
                                                                                  currentGeopoint.longitude);
            
            NSString *currentName = self.guestData[fbId][@"name"];
            UIImage *preImage = self.guestData[fbId][@"userPic"];
            UIImage *postImage = [self resizeImage:preImage];
            self.guestData[fbId][@"userPic"] = postImage;
            
            FBIdAnnotationPoint *point = self.friendAnnotationPointDict[fbId];
            
            if (!point) {
            
                point = [[FBIdAnnotationPoint alloc] initWithFbId:fbId];
                point.coordinate = currentCoordinate;
                point.title = currentName;
                [_mapView addAnnotation:point];
                self.friendAnnotationPointDict[fbId] = point;
                
            } else {
                
                point.coordinate = currentCoordinate;
                
            }
        }
        for (NSString *Id in pastAnnotationIds) {
            [self.mapView removeAnnotation:self.friendAnnotationPointDict[Id]];
            [_friendAnnotationPointDict removeObjectForKey:Id];
        }
        
        for (PFGeoPoint *geoPoint in anonLocations) {
            CLLocationCoordinate2D currentCoordinate = CLLocationCoordinate2DMake(geoPoint.latitude,
                                                                                  geoPoint.longitude);
            
            FBIdAnnotationPoint *point = [[FBIdAnnotationPoint alloc] init];
            point.coordinate = currentCoordinate;
            point.title = @"Anonymous";
            [_anonAnnotationPointDict addObject:point];
            [_mapView addAnnotation:point];
            
        }
        
        if (self.zoomToFit) {
            [self zoomToFitMapAnnotations];
            self.zoomToFit = NO;
        }
        
    }];
    
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"ActiveMapPin"];
    
    if (!pinView) {
        
        FBIdAnnotationPoint *fbIdAnnotation = annotation;
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ActiveMapPin"];
        
        if ([[annotation title] isEqualToString:@"Venue Location"]){
            pinView.pinColor = MKPinAnnotationColorRed;
        } else {
            pinView.pinColor = MKPinAnnotationColorGreen;
            pinView.leftCalloutAccessoryView = [[UIImageView alloc]
                                                initWithImage:self.guestData[fbIdAnnotation.fbId][@"userPic"]];
        }
        
        pinView.canShowCallout = YES;
        
    } else {
        
        pinView.annotation = annotation;
        
    }
    
    return pinView;
}

- (void)zoomToFitMapAnnotations
{
    if ([self.mapView.annotations count] == 0){
        return;
    }
    
    MKMapRect zoomRect = MKMapRectNull;
    
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
        
    }
    
    // Since nav bar is translucent, we have to add an extra bit of inset at the top
    CGFloat navBarHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    [self.mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(50 + navBarHeight, 50, 50, 50) animated:YES];
}
#pragma mark resize profile Pic

- (UIImage *)resizeImage:(UIImage *)oldImage
{
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(32, 32), NO, 0.0);
    [oldImage drawInRect:CGRectMake(0, 0, 32, 32)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CALayer *imageLayer = [CALayer layer];
    imageLayer.frame = CGRectMake(0,0, 32, 32);
    imageLayer.contents = (id) newImage.CGImage;
    
    imageLayer.masksToBounds = YES;
    imageLayer.cornerRadius = 4.0;
    
    UIGraphicsBeginImageContext(newImage.size);
    [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return roundedImage;
}


@end
