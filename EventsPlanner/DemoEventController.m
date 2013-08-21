//
//  DemoEventController.m
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/21/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "DemoEventController.h"

@interface DemoEventController ()

@property (nonatomic, strong) NSString *eventId;
@property CLLocationCoordinate2D venueLocation;

@end

@implementation DemoEventController

- (id)init
{
    self = [super init];
    if (self) {
        self.eventId = @"Fake Event";
        
        self.venueLocation = CLLocationCoordinate2DMake(37.483440, -122.150166);
        
        self.activeDemoController = [[ActiveEventController alloc] initWithEventId:self.eventId venueLocation:self.venueLocation];
        
        PFQuery *fakeEventQuery = [PFQuery queryWithClassName:@"Event"];
        [fakeEventQuery whereKey:@"eventId" equalTo:self.eventId];
        
        [fakeEventQuery getFirstObjectInBackgroundWithBlock:^(PFObject *fakeEvent, NSError *error) {
            __block PFRelation *fakeEventUsers = [fakeEvent relationforKey:@"DummyRelation"];
            PFQuery *fakeEventUsersQuery = [fakeEventUsers query];
            
            [fakeEventUsersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                for( PFObject *fakeUser in objects) {
//                    PFObject *fakeUser = [PFObject objectWithClassName:@"DummyObject"];
//                    [fakeUser setObject:[NSString stringWithFormat:@"%d", rand()] forKey:facebookID];
                    
                    double dLat = ((double)(rand()%5000))/10000.0 -0.25;
                    double dLon = ((double)(rand()%5000))/10000.0 -0.25;
                    PFGeoPoint *fakeUserLocation = [PFGeoPoint geoPointWithLatitude:self.venueLocation.latitude+dLat longitude:self.venueLocation.longitude+dLon];
                    [fakeUser setObject:fakeUserLocation forKey:locationKey];
                    
                    NSDictionary *fakeUserLocationDict = @{locationKey: fakeUserLocation,
                                                           kTimeKey: [NSNumber numberWithDouble: [[NSDate date] timeIntervalSinceReferenceDate]]};
                    [fakeUser setObject:@[fakeUserLocationDict, fakeUserLocationDict] forKey:kLocationData];
                    
                    //[fakeUser save];
                    
                    [fakeEventUsers addObject:fakeUser];
                }
                
                [fakeEvent saveInBackground];
            }];
            
        }];
        
    }
    return self;
}

- (UIViewController *)presentableViewController {


    return [self.activeDemoController presentableViewController];
}

@end
