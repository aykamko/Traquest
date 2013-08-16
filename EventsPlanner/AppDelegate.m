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
#import "FBEventDetailsViewController.h"

static const BOOL debugTracking = YES;

@interface AppDelegate () <UIAlertViewDelegate>

@property (nonatomic, strong) UINavigationController *navController;

@property (nonatomic, strong) EventsListController *eventsListController;
@property (nonatomic, strong) FBLoginViewController *loginViewController;
@property (nonatomic, strong) NSMutableArray *eventsNeedingCertification;

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
    [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge |
                                                     UIRemoteNotificationTypeAlert |
                                                     UIRemoteNotificationTypeSound];
    
    // Google Maps
    [GMSServices provideAPIKey:@"AIzaSyCYlOnjDI2_s5WPCmeQJ7IMozreNxjyDww"];
    
    // Initializing Data Store
    (void) [[ParseDataStore alloc] init];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor brownColor];
    
    self.loginViewController = [[FBLoginViewController alloc] init];
    
    self.navController = [[UINavigationController alloc] initWithRootViewController:self.loginViewController];
    self.window.rootViewController = self.navController;
    
    if ([[ParseDataStore sharedStore] isLoggedIn]) {
        
        [[ParseDataStore sharedStore] fetchAllEventListDataWithCompletion:^(NSArray *activeHostEvents,
                                                                            NSArray *activeGuestEvents,
                                                                            NSArray *hostEvents,
                                                                            NSArray *guestEvents,
                                                                            NSArray *maybeAttendingEvent,
                                                                            NSArray *noReplyEvents) {
            
            self.loginViewController.navigationController.navigationBar.translucent = NO;
            
            _eventsListController = [[EventsListController alloc] initWithActiveHostEvents:activeHostEvents
                                                                         activeGuestEvents:activeGuestEvents
                                                                                hostEvents:hostEvents
                                                                           attendingEvents:guestEvents
                                                                          notRepliedEvents:noReplyEvents
                                                                            maybeAttending:maybeAttendingEvent];
            
            [[self.eventsListController presentableViewController] navigationItem].hidesBackButton = YES;
            
            [self.navController pushViewController:[_eventsListController presentableViewController] animated:YES];
            
            

            
            [self.window makeKeyAndVisible];
            
        }];
        
    } else {
       [self.window makeKeyAndVisible];
    }
    
    return YES;
}

// Parse Push setup
#pragma mark Parse Push Setup
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (!self.eventsNeedingCertification) {
        self.eventsNeedingCertification = [[NSMutableArray alloc] init];
    }
    
    NSString *eventId = userInfo[@"eventId"];
    NSString *eventName = userInfo[@"eventName"];
    
    if (eventId && eventName) {
        [self.eventsNeedingCertification addObject:@{ eventId: eventName }];
        if ([application applicationState] != UIApplicationStateActive) {
            [PFPush handlePush:userInfo];
        } else {
            [self promptUserAllowTrackingForEvent:eventName eventId:eventId];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    for (NSDictionary *event in _eventsNeedingCertification) {
        NSString *eventId = [[event allKeys] firstObject];
        NSString *eventName = event[eventId];
        [self promptUserAllowTrackingForEvent:eventName eventId:eventId];
    }
}


- (void)promptUserAllowTrackingForEvent:(NSString *)eventName eventId:(NSString *)eventId {
    
    NSString *title = @"The following event would like to track your location:";
    
    UIAlertView *trackingPrompt = [[UIAlertView alloc]
                                   initWithTitle:title
                                   message:eventName
                                   delegate:self
                                   cancelButtonTitle:nil
                                   otherButtonTitles:@"Allow Tracking", @"Allow Anonymously", @"Don't Allow", nil];
    
    [trackingPrompt show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSDictionary *event = [self.eventsNeedingCertification firstObject];
    NSString *eventId = [[event allKeys] firstObject];
    
    NSString *identity;
    if (buttonIndex == 0) {
        identity = allowed;
    } else if (buttonIndex == 1) {
        identity = anonymous;
    } else if (buttonIndex == 2) {
        identity = notAllowed;
    }
    
    
    [[ParseDataStore sharedStore] changePermissionForEvent:eventId identity:identity completion:nil];
    [self.eventsNeedingCertification removeObjectAtIndex:0];
    
}

@end
