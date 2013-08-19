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

CGFloat const kCalloutViewProfilePicCornerRadius = 4.0;

@interface ActiveEventMapViewController () <MKMapViewDelegate>

@property (nonatomic) BOOL zoomToFit;

@property (strong, nonatomic) NSMutableDictionary *anonGuestLocations;

@property (nonatomic) CLLocationCoordinate2D venueLocation;
@property (nonatomic, strong) NSDictionary* guestData;


@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) UIView *toastSpinner;

@end

@implementation ActiveEventMapViewController

- (id)initWithEventId:(NSString *)eventId venueLocation:(CLLocationCoordinate2D)venueLocation
{
    self = [super init];
    if (self) {
        
        UITabBarItem *icon = [self tabBarItem];
        UIImage *image= [UIImage imageNamed:@"MarkerFinal.png"];
        [icon setImage:image];
        
        _venueLocation = venueLocation;
        _friendAnnotationPointDict = [[NSMutableDictionary alloc] init];
        _anonAnnotationPointDict = [[NSMutableDictionary alloc] init];
        _guestData = [[NSMutableDictionary alloc] init];
        
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    [self.view addSubview:self.mapView];
    
    [self.mapView setMapType:MKMapTypeStandard];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(_venueLocation, 2500, 2500);
    [self.mapView setRegion:region animated:YES];
    
    MKPointAnnotation *venuePin = [[MKPointAnnotation alloc] init];
    venuePin.coordinate = self.venueLocation;
    venuePin.title = @"Venue Location";
    [self.mapView addAnnotation:venuePin];
    
    self.zoomToFit = YES;
   
}

#pragma mark Adding Annotations and Map View

- (void)updateMarkersOnMapForAllowedUsers:(NSDictionary *)allowedUsersDict anonUsers:(NSDictionary *)anonUsersDict;
{
        // Allowed points
        NSMutableSet *pastAllowedUserIds = [NSMutableSet setWithArray:[self.friendAnnotationPointDict allKeys]];
        
        for (NSString *fbId in [allowedUsersDict allKeys]) {
            PFUser *user = allowedUsersDict[fbId];
            if (!user) {
                continue;
            }
            
            [pastAllowedUserIds removeObject:fbId];
            
            PFGeoPoint *currentGeopoint = [user objectForKey:locationKey];
            
            CLLocationCoordinate2D currentCoordinate = CLLocationCoordinate2DMake(currentGeopoint.latitude,
                                                                                  currentGeopoint.longitude);
            
            FBIdAnnotationPoint *point = self.friendAnnotationPointDict[fbId];
            
            if (!point) {
            
                point = [[FBIdAnnotationPoint alloc] initWithFbId:fbId anonymity:NO];
                point.coordinate = currentCoordinate;
                point.title = [user objectForKey:kParseUserNameKey];
                [self.mapView addAnnotation:point];
                self.friendAnnotationPointDict[fbId] = point;
                
            } else {
                
                point.coordinate = currentCoordinate;
                
            }
        }
        
        for (NSString *key in pastAllowedUserIds) {
            [self.mapView removeAnnotation:self.friendAnnotationPointDict[key]];
            [self.friendAnnotationPointDict removeObjectForKey:key];
        }
        
        // Anonymous points
        NSMutableSet *pastAnonymousLocationIds = [NSMutableSet setWithArray:[self.anonAnnotationPointDict allKeys]];
        
        for (NSString *fbIdHash in [anonUsersDict allKeys]) {
            PFUser *anonUser = anonUsersDict[fbIdHash];
            if (!anonUser) {
                continue;
            }
            
            [pastAnonymousLocationIds removeObject:fbIdHash];
            
            PFGeoPoint *geoPoint = [anonUser objectForKey:locationKey];
            
            CLLocationCoordinate2D currentCoordinate = CLLocationCoordinate2DMake(geoPoint.latitude,
                                                                                  geoPoint.longitude);
            
            FBIdAnnotationPoint *point = self.anonAnnotationPointDict[fbIdHash];
            
            if (!point) {
                
                point = [[FBIdAnnotationPoint alloc] initWithFbId:fbIdHash anonymity:YES];
                point.coordinate = currentCoordinate;
                point.title = @"Anonymous";
                [self.mapView addAnnotation:point];
                self.anonAnnotationPointDict[fbIdHash] = point;
                
            } else {
                
                point.coordinate = currentCoordinate;
                
            }
            
        }
        
        for (NSString *key in pastAnonymousLocationIds) {
            [self.mapView removeAnnotation:self.anonAnnotationPointDict[key]];
            [self.anonAnnotationPointDict removeObjectForKey:key];
        }
        
        if (self.zoomToFit) {
            [self zoomToFitMapAnnotations];
            self.zoomToFit = NO;
        }
    
    
    
   

}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        ((MKUserLocation *)annotation).title = nil;
        return nil;
    }
    
    static NSString *annotationViewIdentifier = @"ActiveMapPin";
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationViewIdentifier];
    
    if (!pinView) {
        
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationViewIdentifier];
        
        if ([annotation isMemberOfClass:[FBIdAnnotationPoint class]]) {
            pinView.image = [UIImage imageNamed:@"greenLocation.png"];

            FBIdAnnotationPoint *fbAnnotation = (FBIdAnnotationPoint *)annotation;
            pinView.image = [UIImage imageNamed:@"greenLocation.png"];

            
            if (fbAnnotation.anonymous == NO) {
                
                UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                                    initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                pinView.leftCalloutAccessoryView = spinner;
                [spinner startAnimating];
                
                [[ParseDataStore sharedStore] fetchProfilePictureForUser:fbAnnotation.fbId completion:^(UIImage *profilePic) {
                    
                    [spinner stopAnimating];
                    
                    UIImageView *profilePicImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
                    profilePicImageView.image = profilePic;
                    [profilePicImageView.layer setCornerRadius:kCalloutViewProfilePicCornerRadius];
                    
                    pinView.leftCalloutAccessoryView = profilePicImageView;
                    
                }];
            }
            
        } else {
            
            pinView.pinColor = MKPinAnnotationColorRed;
            
        }
        
      
        
     
        
        
    } else {
        
        pinView.annotation = annotation;
        
    }
    pinView.canShowCallout = YES;
   // pinView.animatesDrop = YES;
    return pinView;
}

- (void)zoomToFitMapAnnotations
{
    if ([self.mapView.annotations count] <= 1){
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

@end
