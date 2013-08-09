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

@interface AppDelegate ()  {
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
    [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    
    // Google Maps
    [GMSServices provideAPIKey:@"AIzaSyCYlOnjDI2_s5WPCmeQJ7IMozreNxjyDww"];
    
    // Initializing Data Store
    (void) [[ParseDataStore alloc] init];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor brownColor];
    
    _loginViewController = [[LoginViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:_loginViewController];
    
    if ([[ParseDataStore sharedStore] isLoggedIn]) {
        
        [[ParseDataStore sharedStore] fetchEventListDataWithCompletion:^(NSArray *hostEvents, NSArray *guestEvents, NSArray *maybeAttendingEvent, NSArray *noReplyEvents) {
            
            _eventsListController = [[EventsListController alloc] initWithHostEvents:hostEvents
                                                                         guestEvents:guestEvents
                                                                       noReplyEvents:noReplyEvents
                                                                      maybeAttending:maybeAttendingEvent];
            
            [[self.eventsListController presentableViewController] navigationItem].hidesBackButton = YES;
            
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

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (application.applicationState != UIApplicationStateActive) {
        [PFPush handlePush:userInfo];
    } else {
        UIAlertView *pushAlert = [[UIAlertView alloc] initWithTitle:@"Title"
                                                            message:@"Message"
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", @"Anonomously", nil];
        [pushAlert show];
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [_locationTrackingTimer invalidate];
    [[ParseDataStore sharedStore] startTrackingMyLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[ParseDataStore sharedStore] stopTrackingMyLocation];
}

//- (void)applicationWillEnterForeground:(UIApplication *)application
//{
//}
//
//- (void)applicationWillTerminate:(UIApplication *)application
//{
//}
//
//- (void)applicationWillResignActive:(UIApplication *)application
//{
//}

@end
