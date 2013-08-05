//
//  ParseDataStore.m
//  EventsPlanner
//
//  Created by Anupa Murali on 8/2/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "ParseDataStore.h"

@interface ParseDataStore () <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *userPastLocations;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) NSArray *friendsIDArray;
@property (strong, nonatomic) NSMutableArray *allAttendingFriends;
@end
@implementation ParseDataStore

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedStore];
}

+ (ParseDataStore *)sharedStore
{
    static ParseDataStore *sharedStore = nil;
    if (!sharedStore)
        sharedStore = [[super allocWithZone:nil] init];
    
    return sharedStore;
}

- (BOOL)isLoggedIn
{
    if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
        return YES;
    
    return NO;
}

- (void)startTrackingLocation
{
    if (![self isLoggedIn]) {
        NSLog(@"Not logged in, can't track location");
        return;
    }
    
    _locationManager = [[CLLocationManager alloc] init];
    
    [_locationManager setDelegate:self];
    [_locationManager startMonitoringSignificantLocationChanges];
    
    [[PFUser currentUser] setObject:@"YES" forKey:@"trackingAllowed"];
    
    [[PFUser currentUser] saveInBackground];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* location = [locations lastObject];
    
    CLLocationCoordinate2D coordinate = [location coordinate];
    _currentLocation = location;
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                  longitude:coordinate.longitude];
    
    
    [[PFUser currentUser] setObject:geoPoint forKey:@"location"];
    NSLog(@"I'm here, %@",_currentLocation);
    [_userPastLocations addObject:geoPoint];
    [[PFUser currentUser] saveInBackground];
}


-(void)fetchLocationDataWithCompletion:(void (^)(NSArray *userLocations)) completionBlock{
    NSMutableArray *locations;
    [self fetchFriendsWithCompletion:^(NSArray *friends) {
        PFQuery *locationQuery = [PFUser query];
        [locationQuery whereKey: @"trackingAllowed" equalTo:@"YES"];
        [locationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            for (PFUser *friend in objects){
                if ([friends containsObject:friend])
                {
                    [locations addObject:friend[@"locations"]];
                }
            }
        }];
        
    }];
    completionBlock(locations);
}



-(void)logOutWithCompletion:(void (^)())completionBlock{
    [[PFFacebookUtils session]closeAndClearTokenInformation];
    [PFUser logOut];
    completionBlock();
}

- (void)logInWithCompletion:(void (^)())completionBlock
{
    
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[@"user_events"];
    
    // Login PFUser using facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        
        if (!user) {
            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error"
                                                                message:@"Uh oh. The user cancelled the Facebook login."
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Dismiss", nil];
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error"
                                                                message:[error description]
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
        } else {
            completionBlock();
        }
    }];
}


- (void)fetchEventListDataWithCompletion:(void (^)(NSArray *hostEvents, NSArray *guestEvents, NSArray *friends))completionBlock
{
    
    FBRequest *request = [FBRequest requestForGraphPath:
                          @"me?fields=events.limit(1000).fields(name,admins.fields(id,name),"
                          @"attending.limit(5),location,cover,owner,"
                          @"privacy,description,venue,picture,rsvp_status),id"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            NSString *myID = result[@"id"];
            
            // Save the logged in user's Facebook ID to parse
            [[PFUser currentUser] setObject:myID forKey:@"fbID"];
            [[PFUser currentUser] saveInBackground];
            
            FBGraphObject *fbGraphObj = (FBGraphObject *)result;
            NSArray *eventArray = fbGraphObj[@"events"][@"data"];
            NSMutableArray *hostEvents = [[NSMutableArray alloc] init];
            NSMutableArray *guestEvents = [[NSMutableArray alloc] init];
            NSArray *friends = [[NSMutableArray alloc] init];
            friends = fbGraphObj[@"events"][@"attending"][@"id"];
            
            for (FBGraphObject *event in eventArray) {
                
                NSArray *adminArray = event[@"admins"][@"data"];
                
                BOOL isHost = NO;
                for (FBGraphObject *adminData in adminArray) {
                    if ([adminData[@"id"] isEqualToString:myID]) {
                        isHost = YES;
                        break;
                    }
                }
                
                if (isHost == YES) {
                    [hostEvents insertObject:event atIndex:0];
                } else {
                    [guestEvents insertObject:event atIndex:0];
                }
                
            }
            completionBlock(hostEvents, guestEvents, friends);
            _friendsIDArray = friends;
        }
    }];
    
}

    
-(void)fetchFriendsWithCompletion:(void (^)(NSArray *friends)) completionBlock{
    NSMutableArray *attendingFriends = [[NSMutableArray alloc] init];
    PFQuery *friendsIDQuery = [PFUser query];
    [friendsIDQuery whereKey:@"fbID" containedIn:_friendsIDArray];
    [friendsIDQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
        for (PFUser *friend in objects)
        {
            [attendingFriends addObject:friend];
        }
    }];
    completionBlock(attendingFriends);
}
    
    

@end
