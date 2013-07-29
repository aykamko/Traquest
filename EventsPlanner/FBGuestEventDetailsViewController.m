//
//  FBEventDetailsViewController.m
//  EventsPlanner
//
//  Created by Ashwin Murthy on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBGuestEventDetailsViewController.h"
#import "MapPoint.h"

@interface FBGuestEventDetailsViewController (){

    NSDictionary *_eventDetails;
}

@end

@implementation FBGuestEventDetailsViewController

- (id)initWithEventDetails:(NSDictionary *)details
{
    self = [super init];
    if (self) {
        _eventDetails = details;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSString *locationAddress = [_eventDetails objectForKey:@"location"];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:locationAddress completionHandler:^(NSArray* placemarks, NSError* error){
        
        CLPlacemark *aPlacemark = [placemarks firstObject];
        double latitude = aPlacemark.location.coordinate.latitude;
        double longitude = aPlacemark.location.coordinate.longitude;
        
        CLLocationCoordinate2D eventLocation = CLLocationCoordinate2DMake(latitude, longitude);
        MapPoint *add_Annotation = [[MapPoint alloc] initWithCoordinate:eventLocation title:@"myTitle"];
        [_eventMapView addAnnotation:add_Annotation];
        NSLog(@"%f,%f",latitude,longitude);
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(eventLocation, 5000, 2500);
        [_eventMapView setRegion:region animated:NO];
        
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    if (![[PFUser currentUser] objectForKey:@"trackingAllowed"])
    {
        UIAlertView *requestTracking = [[UIAlertView alloc] initWithTitle:@"Hi!" message:@"Allow the host to see where you are" delegate:nil cancelButtonTitle: @"Done" otherButtonTitles:@"YES",@"Anonymous",@"NO"];
    }
    
    else
    {
//        MapPoint *add_Annotation = [[MapPoint alloc] initWithCoordinate:eventLocation title:@"myTitle"];
   
    }
}

@end