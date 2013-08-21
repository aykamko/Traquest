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
@property (nonatomic, strong) NSMutableDictionary *directions;
@property (nonatomic, strong) NSMutableDictionary *distances;
@property (nonatomic, strong) NSMutableDictionary *times;
@property (nonatomic, strong) NSTimer *timer;


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
        
        self.directions =  [[NSMutableDictionary alloc] init];
        self.distances =  [[NSMutableDictionary alloc] init];
        self.times =  [[NSMutableDictionary alloc] init];

        
        [fakeEventQuery getFirstObjectInBackgroundWithBlock:^(PFObject *fakeEvent, NSError *error) {
            __block PFRelation *fakeEventUsers = [fakeEvent relationforKey:@"DummyRelation"];
            PFQuery *fakeEventUsersQuery = [fakeEventUsers query];
            
            [fakeEventUsersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                for( PFObject *fakeUser in objects) {
//                    PFObject *fakeUser = [PFObject objectWithClassName:@"DummyObject"];
//                    [fakeUser setObject:[NSString stringWithFormat:@"%d", rand()] forKey:facebookID];
                    NSString *fakeUserId = fakeUser[facebookID];
                    
                    double dLat = ((double)(rand()%5000))/10000.0 -0.25;
                    double dLon = ((double)(rand()%5000))/10000.0 -0.25;
                    
                    double length = hypot(dLon, dLat);
                    
                    int time = rand()%30 + 10;
                    [self.times setObject:[NSNumber numberWithInt:time] forKey:fakeUserId];
                    
                    [self.distances setObject:[NSNumber numberWithDouble:length] forKey:fakeUserId];
                    
                    [self.directions setObject:[NSNumber numberWithDouble:(-dLat/length)] forKey:[NSString stringWithFormat:@"Lat%@",fakeUserId]];
                    [self.directions setObject:[NSNumber numberWithDouble:(-dLon/length)] forKey:[NSString stringWithFormat:@"Lon%@",fakeUserId]];
                    NSLog(@"%@",self.directions);
                    
                    PFGeoPoint *fakeUserLocation = [PFGeoPoint geoPointWithLatitude:self.venueLocation.latitude+dLat longitude:self.venueLocation.longitude+dLon];
                    [fakeUser setObject:fakeUserLocation forKey:locationKey];
                    
                    NSDictionary *fakeUserLocationDict = @{locationKey: fakeUserLocation,
                                                           kTimeKey: [NSNumber numberWithDouble: [[NSDate date] timeIntervalSinceReferenceDate]]};
                    [fakeUser setObject:@[fakeUserLocationDict, fakeUserLocationDict] forKey:kLocationData];
                    
                    [fakeUser save];
                    
                    [fakeEventUsers addObject:fakeUser];
                    
                }
                self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(movePoints) userInfo:nil repeats:YES];
                [self.timer fire];
                NSLog(@"%@",self.directions);
            }];
            
        }];
        
    }
    return self;
}

- (void)movePoints {
    PFQuery *dummyObjectQuery = [PFQuery queryWithClassName:@"DummyObject"];
    PFGeoPoint *venueGeoPoint = [PFGeoPoint geoPointWithLatitude:self.venueLocation.latitude longitude:self.venueLocation.longitude];
    [dummyObjectQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        for (PFObject *dummyObject in objects) {
            NSString *fakeId = [dummyObject objectForKey:facebookID];
            NSArray *locationsArray = [dummyObject objectForKey:kLocationData];
            NSDictionary *locationDataDict = [locationsArray objectAtIndex:1];
            PFGeoPoint *currentLocation = locationDataDict[locationKey];
            
            if ([currentLocation distanceInMilesTo:venueGeoPoint]<0.5) {
                continue;
            }
            NSNumber *distance = self.distances[fakeId];
            NSNumber *timeSteps = self.times[fakeId];
            double magnitude = [distance doubleValue]/[timeSteps doubleValue];
            
            double deltaLat = [self.directions[[NSString stringWithFormat:@"Lat%@",fakeId ]] doubleValue]*magnitude;
            double deltaLon = [self.directions[[NSString stringWithFormat:@"Lon%@",fakeId ]] doubleValue]*magnitude;
            PFGeoPoint *newLocation = [PFGeoPoint geoPointWithLatitude:currentLocation.latitude+deltaLat
                                                             longitude:currentLocation.longitude+deltaLon];
            [dummyObject setObject:newLocation forKey:locationKey];
            
            NSDictionary *newDict = @{ locationKey: newLocation,
                                       kTimeKey: [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate]] };
            locationsArray = @[[locationsArray firstObject], newDict];
            [dummyObject setObject:locationsArray forKey:kLocationData];
            [dummyObject saveInBackground];
        }
    }];
}

- (UIViewController *)presentableViewController {


    return [self.activeDemoController presentableViewController];
}

@end
