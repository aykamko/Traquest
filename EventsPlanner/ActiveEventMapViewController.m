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
#import "AnnotationPoint.h"

static const NSInteger UpdateFrequencyInSeconds = 3.0;

@interface ActiveEventMapViewController (){
    
   MKMapView *_mapView;
    GMSCoordinateBounds *_bounds;
    UIImage *_currentImage;
    CLLocationCoordinate2D _venueLocation;
    MKPointAnnotation *_venuePin;
    NSMutableDictionary *_guestDetails;
    NSMutableDictionary *_FbIdAnnot;
    CLLocationManager *_locationManager;
}

@property (nonatomic) BOOL zoomToFit;
@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSString *eventId;
@property (strong, nonatomic) NSMutableDictionary *friendDetailsDict;
@property (strong, nonatomic) NSMutableDictionary *friendAnnotationPointDict;

@property (strong, nonatomic) UIView *toastSpinner;

@end

@implementation ActiveEventMapViewController

- (id)initWithGuestArray:(NSArray *)guestArray eventId:(NSString *)eventId venueLocation:(CLLocationCoordinate2D)venueLocation
{
    self = [super init];
    if (self) {

        _locationManager=[[CLLocationManager alloc]init];
        
        [_locationManager setDelegate: self];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];

        UITabBarItem *icon = [self tabBarItem];
        UIImage *image= [UIImage imageNamed:@"MarkerFinal.png"];
        [icon setImage:image];
        
        _venueLocation = venueLocation;
        _eventId = eventId;
        _friendAnnotationPointDict = [[NSMutableDictionary alloc] init];
        _FbIdAnnot = [[NSMutableDictionary alloc]init];
        _friendDetailsDict = [[NSMutableDictionary alloc] init];
        for (FBGraphObject *user in guestArray) {
            UIImage *userPic = [[UIImage alloc]initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:user[@"picture"][@"data"][@"url"]]]];
            NSMutableDictionary *friendDetailsSubDict = [[NSMutableDictionary alloc]
                                                         initWithDictionary:@{ @"geopoint":[NSNull null],
                                                                               @"name":user[@"name"],
                                                                               @"userPic":userPic }];

            [[self friendDetailsDict] addEntriesFromDictionary:@{ user[@"id"]:friendDetailsSubDict }];
        }
        
        self.zoomToFit = YES;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:UpdateFrequencyInSeconds
                                                      target:self
                                                    selector:@selector(updateMarkersOnMap)
                                                    userInfo:nil
                                                     repeats:YES];
        [self.timer fire];
        
    }
    
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(_venueLocation, 500, 500);
    _mapView = [[MKMapView alloc]initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    [_mapView setRegion:region animated:YES];
    [_mapView setMapType:MKMapTypeStandard];
    MKPointAnnotation *venuePin = [[MKPointAnnotation alloc]init];
    venuePin.coordinate = _venueLocation;
    venuePin.title = @"Venue Location" ;
    [_mapView addAnnotation:venuePin];
    
}

- (void)updateMarkersOnMap


{
    [[ParseDataStore sharedStore] fetchGeopointsForIds:[self.friendDetailsDict allKeys] eventId:self.eventId completion:^(NSDictionary *userLocations) {
        
        for (NSString *fbId in [userLocations allKeys]) {
            
            if ([fbId isEqualToString:[[ParseDataStore sharedStore] myId]]) {
                continue;
            }
            
            self.friendDetailsDict[fbId][@"geopoint"] = userLocations[fbId];
            PFGeoPoint *currentGeopoint = self.friendDetailsDict[fbId][@"geopoint"];
            
            CLLocationCoordinate2D currentCoordinate = CLLocationCoordinate2DMake(currentGeopoint.latitude,
                                                                                  currentGeopoint.longitude);
            
            NSString *currentName = self.friendDetailsDict[fbId][@"name"];
            UIImage *preImage = self.friendDetailsDict[fbId][@"userPic"];
            UIImage *postImage = [self resizeImage:preImage];
            self.friendDetailsDict[fbId][@"userPic"] = postImage;
            
            AnnotationPoint *point = self.friendAnnotationPointDict[fbId];
            
            if (!point) {
            
                point = [[AnnotationPoint alloc] initWithFbId:fbId];
                point.coordinate = currentCoordinate;
                point.title = currentName;
                [_mapView addAnnotation:point];
                self.friendAnnotationPointDict[fbId] = point;
                
            } else {
                
                point.coordinate = currentCoordinate;
                
            }
        }
        
        if (self.zoomToFit) {
            [self zoomToFitMapAnnotations];
            self.zoomToFit = NO;
        }
        
    }];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.timer invalidate];
    self.timer = nil;
}

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


-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *pinView = (MKPinAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:@"myAnnotation"];
    if(!pinView){
        AnnotationPoint *customAnnotation = annotation;
        pinView= [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"myAnnotation"];
        if([[annotation title] isEqualToString:@"Venue Location"]){
            pinView.pinColor = MKPinAnnotationColorRed;
            
        }
        
        else
        {
            pinView.pinColor = MKPinAnnotationColorGreen;
            pinView.leftCalloutAccessoryView = [[UIImageView alloc]initWithImage:self.friendDetailsDict[customAnnotation.fbId][@"userPic"]];
            // pinView.image = _currentImage;
        }
        
        pinView.canShowCallout = YES;
    }
    
    else{
        pinView.annotation = annotation;
    }
    
    
    
    return pinView;
}

-(void)zoomToFitMapAnnotations{
    if([_mapView.annotations count] ==0){
        return;
    }
    
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in _mapView.annotations)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x+0.01, annotationPoint.y-0.01, -1, -1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
        
    }
    [_mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(50,50,50,50) animated:YES];
}

@end
