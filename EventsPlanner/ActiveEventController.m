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

<<<<<<< HEAD
@interface ActiveEventController () 

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CLLocationCoordinate2D venueLocation;

@property (strong, nonatomic) NSString *eventId;
=======
@interface ActiveEventController ()

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CLLocationCoordinate2D venueLocation;
@property NSString *eventId;
>>>>>>> Fetched data better

@property (strong, nonatomic) NSMutableDictionary *friendAnnotationPointDict;
@property (strong, nonatomic) NSMutableDictionary *anonAnnotationPointDict;

<<<<<<< HEAD
@property (weak, nonatomic) ActiveEventMapViewController *mapController;
@property (weak, nonatomic) ActiveEventsStatsViewController *statsController;
@property (strong, nonatomic) UITabBarController *tabBarController;
=======
@property ActiveEventMapViewController *mapController;
@property ActiveEventsStatsViewController *statsController;
@property UITabBarController *tabBarController;
>>>>>>> Fetched data better

@end

@implementation ActiveEventController

- (id)initWithEventId: (NSString *) eventId venueLocation:(CLLocationCoordinate2D)venueLocation
{
    self = [super init];
    if (self) {
        [self setEventId:eventId];
        
        _venueLocation = venueLocation;
        
        _tabBarController = [[UITabBarController alloc] init];
<<<<<<< HEAD
        ActiveEventMapViewController *mapController = [[ActiveEventMapViewController alloc]
                                                       initWithEventId:eventId venueLocation:venueLocation];
        ActiveEventsStatsViewController *statsController = [[ActiveEventsStatsViewController alloc]
                                                            initWithEventId:eventId
                                                            venueLocation:venueLocation];
        
        [_tabBarController setViewControllers:@[mapController, statsController]];
        
        self.mapController = mapController;
        self.statsController = statsController;
        self.statsController.title = @"Stats";
        self.mapController.title = @"Map";
    }
    return self;
}

- (void)startTimerForUpdates:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIViewController *nextController = [userInfo objectForKey:@"UINavigationControllerNextVisibleViewController"];
    if (nextController == self.tabBarController) {
=======
        _mapController = [[ActiveEventMapViewController alloc] initWithEventId:eventId venueLocation:venueLocation];
        _statsController = [[ActiveEventsStatsViewController alloc] initWithEventId:eventId venueLocation:venueLocation];
        
        [_tabBarController setViewControllers:@[_mapController, _statsController]];
        _statsController.title = @"Stats";
        _mapController.title = @"Map";
        
        
>>>>>>> Fetched data better
        [self setTimer:[NSTimer scheduledTimerWithTimeInterval:UpdateFrequencyInSeconds
                                                                                      target:self
                                                                                    selector:@selector(updateLocationData)
                                                                                    userInfo:nil
                                                                                     repeats:YES]];
        [[self timer] fire];
<<<<<<< HEAD
    } else {
        [self.timer invalidate];
        self.timer = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)updateLocationData
{
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
        
        [self.mapController updateMarkersOnMapForAllowedUsers:allowedUserDict anonUsers:anonUserDict];
        
    }];
}

- (UITabBarController *) presentableViewController {
    return self.tabBarController;
=======
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

- (void)goBack {
    [self.timer invalidate];
    self.timer = nil;
    [self.tabBarController.navigationController popViewControllerAnimated:YES];
}

-(UITabBarController *) presentableViewController {
    return _tabBarController;
>>>>>>> Fetched data better
}

@end
