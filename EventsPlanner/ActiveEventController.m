//
//  ActiveEventsController.m
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/17/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "ActiveEventController.h"
#import "ActiveEventMapViewController.h"
#import "ActiveEventsStatsViewController.h"
#import "ParseDataStore.h"

static const NSInteger UpdateFrequencyInSeconds = 4.0;

@interface ActiveEventController ()

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CLLocationCoordinate2D venueLocation;

@property NSString *eventId;

@property (strong, nonatomic) NSMutableDictionary *friendAnnotationPointDict;
@property (strong, nonatomic) NSMutableDictionary *anonAnnotationPointDict;

@property ActiveEventMapViewController *mapController;
@property ActiveEventsStatsViewController *statsController;
@property UITabBarController *tabBarController;

@end

@implementation ActiveEventController

- (id)initWithEventId: (NSString *) eventId venueLocation:(CLLocationCoordinate2D)venueLocation
{
    self = [super init];
    if (self) {
        [self setEventId:eventId];
        
        _venueLocation = venueLocation;
        
        _tabBarController = [[UITabBarController alloc] init];
        _mapController = [[ActiveEventMapViewController alloc] initWithEventId:eventId venueLocation:venueLocation];
        _statsController = [[ActiveEventsStatsViewController alloc] initWithEventId:eventId venueLocation:venueLocation];
        
        [_tabBarController setViewControllers:@[_mapController, _statsController]];
        _statsController.title = @"Stats";
        _mapController.title = @"Map";
        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cheese"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(goBack)];
        
        self.tabBarController.navigationItem.leftBarButtonItem = backButton;
        
        [self setTimer:[NSTimer scheduledTimerWithTimeInterval:UpdateFrequencyInSeconds
                                                                                      target:self
                                                                                    selector:@selector(updateLocationData)
                                                                                    userInfo:nil
                                                                                     repeats:YES]];
        [[self timer] fire];
    }
    return self;
}

- (void)updateLocationData {
    [[ParseDataStore sharedStore] fetchUsersForEvent:self.eventId completion:^(NSArray *allowedUsers, NSArray *anonUsers) {
        
        NSMutableDictionary *allowedUserDict = [[NSMutableDictionary alloc] init];
        for (PFUser *user in allowedUsers) {
            [allowedUserDict setObject:user forKey:user[facebookID]];
        }
        
        NSMutableDictionary *anonUserDict = [[NSMutableDictionary alloc] init];
        for (PFUser *user in anonUsers) {
            NSString *key = [NSString stringWithFormat:@"%d",[user[facebookID] hash]];
            [anonUserDict setObject:user forKey:key];
        }
        
        [_mapController updateMarkersOnMapForAllowedUsers:allowedUserDict anonUsers:anonUserDict];
        
    }];
}

- (void)goBack
{
    [self.timer invalidate];
    self.timer = nil;
    [self.tabBarController.navigationController popViewControllerAnimated:YES];
}

-(UITabBarController *) presentableViewController {
    return _tabBarController;
}

@end
