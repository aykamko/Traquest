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
    NSNumber *tracking = [[PFUser currentUser] objectForKey:@"trackingAllowed"];
    if([tracking isEqualToNumber:@0])
    {
        
        UIAlertView *requestTracking = [[UIAlertView alloc] initWithTitle:@"Hi!" message:@"Allow the host to see where you are" delegate:nil cancelButtonTitle: @"YES" otherButtonTitles:@"Anonymous",@"NO",nil];
        requestTracking.cancelButtonIndex = -1;
        [requestTracking show];
       
    }
    else
    {
        PFGeoPoint *guestLocation = [[PFUser currentUser] objectForKey:@"location"];
        CLLocationCoordinate2D guestCoordinate = CLLocationCoordinate2DMake(guestLocation.latitude, guestLocation.longitude);
        MapPoint *add_Annotation = [[MapPoint alloc] initWithCoordinate: guestCoordinate title:@"guestTitle"];
        NSLog(@"Greetings, %f,%f",guestCoordinate.latitude,guestCoordinate.longitude);
    
        [_eventMapView addAnnotation:add_Annotation];
    }
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
@end