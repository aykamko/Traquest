//
//  AppDelegate.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <GoogleMaps/GoogleMaps.h>
#import "LoginViewController.h"
#import "ParseDataStore.h"
#import "EventsListController.h"

static const BOOL debugTracking = YES;

@interface AppDelegate ()<CLLocationManagerDelegate>  {
    CLLocationManager *locationManager;
    NSTimer *_locationTrackingTimer;
}

@property (nonatomic, strong) EventsListController *eventsListController;
@property (nonatomic, strong) LoginViewController *loginViewController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [PFFacebookUtils handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Parse
    [Parse setApplicationId:@"Xz7dF37SCpQkd2evgR4IeLUhhiMBTOMLTrKU06GE"
                  clientKey:@"oorBErIwapu2EDFwbJIkpOZVAEQUhuPV3azWbD0m"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFFacebookUtils initializeFacebook];
    
    // Parse Push setup
//    [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    
    // Google Maps
    [GMSServices provideAPIKey:@"AIzaSyCYlOnjDI2_s5WPCmeQJ7IMozreNxjyDww"];
    
    // Initializing Data Store
    (void) [[ParseDataStore alloc] init];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor brownColor];
    
    _loginViewController = [[LoginViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:_loginViewController];
    
    if ([[ParseDataStore sharedStore] isLoggedIn]) {
        
        [[ParseDataStore sharedStore] fetchEventListDataWithCompletion:^(NSArray *hostEvents, NSArray *guestEvents) {
            
            _eventsListController = [[EventsListController alloc] initWithHostEvents:hostEvents guestEvents:guestEvents];
            UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
            [navController pushViewController:[_eventsListController presentableViewController] animated:YES];
            [self.window makeKeyAndVisible];
            
        }];
        
    } else {
        
        [self.window makeKeyAndVisible];
        
    }
    
    return YES;
}

// Parse Push setup

/*
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}
*/


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [_locationTrackingTimer invalidate];
    [locationManager startMonitoringSignificantLocationChanges];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [locationManager stopMonitoringSignificantLocationChanges];
    
    [locationManager startUpdatingLocation];
//    NSTimeInterval time = 15.0;
//    _locationTrackingTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(updateLocation:)userInfo:nil repeats:YES];
//    [_locationTrackingTimer fire];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray *)locations {
    if(locations && [[ParseDataStore sharedStore] isLoggedIn]) {
        PFGeoPoint *location = [PFGeoPoint geoPointWithLocation:[locations objectAtIndex:0]];
        [[PFUser currentUser] setObject:location forKey:@"location"];
        [[PFUser currentUser] saveInBackground];
    }
}

-(void) updateLocation: (NSTimer *) timer {
    [locationManager stopUpdatingLocation];
}

@end