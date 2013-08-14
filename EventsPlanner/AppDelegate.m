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
#import "FBLoginViewController.h"
#import "ParseDataStore.h"
#import "EventsListController.h"

static const BOOL debugTracking = YES;

@interface AppDelegate () <UIAlertViewDelegate>

@property (nonatomic, strong) EventsListController *eventsListController;
@property (nonatomic, strong) FBLoginViewController *loginViewController;
@property (nonatomic, strong) NSMutableDictionary *eventsNeedingCertification;

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
    
    // Google Maps
    [GMSServices provideAPIKey:@"AIzaSyCYlOnjDI2_s5WPCmeQJ7IMozreNxjyDww"];
    
    // Initializing Data Store
    (void) [[ParseDataStore alloc] init];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor brownColor];
    
    _loginViewController = [[FBLoginViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:_loginViewController];
    
    if ([[ParseDataStore sharedStore] isLoggedIn]) {
        
        [[ParseDataStore sharedStore] fetchEventListDataWithCompletion:^(NSArray *hostEvents, NSArray *guestEvents, NSArray *maybeAttendingEvent, NSArray *noReplyEvents) {
            
            self.loginViewController.navigationController.navigationBar.translucent = NO;
            
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
    if (!_eventsNeedingCertification) {
        _eventsNeedingCertification = [[NSMutableDictionary alloc] init];
    }
    NSString *eventId = userInfo[@"eventId"];
    NSString *eventName = userInfo[@"eventName"];
    [_eventsNeedingCertification setObject:eventName forKey:eventId];
    if ([application applicationState] != UIApplicationStateActive) {
        [PFPush handlePush:userInfo];
    }
    else {
        [self promptUserAllowTracking: eventName withId: eventId];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[ParseDataStore sharedStore] startTrackingMyLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    for (NSString *eventId in _eventsNeedingCertification) {
        [self promptUserAllowTracking:_eventsNeedingCertification[eventId] withId:eventId];
    }
    //[[ParseDataStore sharedStore] stopTrackingMyLocation];
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

- (void)applicationWillResignActive:(UIApplication *)application
{
}

-(void) promptUserAllowTracking: (NSString *) eventName withId: (NSString *) eventId{
    NSString *title = [NSString stringWithFormat:@"The following event would like to track your location:"];
    UIAlertView *trackingPrompt = [[UIAlertView alloc] initWithTitle: title message:eventName delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Allow Tracking", @"Allow Anonymously", @"Don't Allow", nil];
    [trackingPrompt show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *eventName = [alertView message];
    NSString *eventId = [[_eventsNeedingCertification allKeysForObject:eventName] objectAtIndex:0];
    if (buttonIndex==1) {
        [[ParseDataStore sharedStore] changePermissionForEvent:eventId identity:allowed];
     } else if (buttonIndex==2) {
         [[ParseDataStore sharedStore] changePermissionForEvent:eventId identity:anonymous];
     } else if (buttonIndex==3) {
         [[ParseDataStore sharedStore] changePermissionForEvent:eventId identity:notAllowed];
     }
     [_eventsNeedingCertification removeObjectForKey:eventId];
}
@end
