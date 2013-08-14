//
//  ParseDataStore.m
//  EventsPlanner
//
//  Created by Anupa Murali on 8/2/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "ParseDataStore.h"
#import "UIImage+ImageCrop.h"
#import "FBGraphObject+FixEventCoverPhoto.h"

#pragma mark Parse String Keys

NSString * const allowed = @"allowed";
NSString * const anonymous = @"anonymous";
NSString * const notAllowed = @"notAllowed";

NSString * const locationKey = @"location";
NSString * const facebookID = @"fbID";
NSString * const trackingObject = @"trackingDictionary";

@interface ParseDataStore () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *userPastLocations;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) NSMutableArray *allAttendingFriends;

@property (copy, nonatomic) void (^locationCompletionBlock)(CLLocation *location);

@end

@implementation ParseDataStore

#pragma mark - Class Methods

- (id)init
{
    self = [super init];
    if (self) {
        
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        CLLocationDistance distance = 50.0;
        [_locationManager setDistanceFilter:distance];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
        _trackingCount = [[NSMutableDictionary alloc]init];
        
    }
    
    return self;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedStore];
}

+ (ParseDataStore *)sharedStore
{
    static ParseDataStore *sharedStore = nil;
    if (!sharedStore) {
        sharedStore = [[super allocWithZone:nil] init];
    }
    
    return sharedStore;
}

#pragma mark - Login

- (BOOL)isLoggedIn
{
    if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
        return YES;
    
    return NO;
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    
    if (self.locationCompletionBlock) {
        [self.locationManager stopUpdatingLocation];
        self.locationCompletionBlock(location);
    }
    
    CLLocationCoordinate2D coordinate = [location coordinate];
    _currentLocation = location;
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                  longitude:coordinate.longitude];
    
    
    [[PFUser currentUser] setObject:geoPoint forKey:@"location"];
    [_userPastLocations addObject:geoPoint];
    [[PFUser currentUser] saveInBackground];
}

-(void)fetchLocationDataForIds: (NSDictionary *) guestDetails
{    
    PFQuery *trackingQuery = [PFUser query];
    [trackingQuery whereKey: @"fbID" containedIn:[guestDetails allKeys]];
    //[trackingQuery whereKey:@"trackingAllowed" equalTo:@"YES"];
    
    [trackingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for (PFUser *friend in objects) //for every user that allows tracking
        {
            NSString *friendID = friend[@"fbID"];
            guestDetails[friendID][@"location"] = friend[@"location"];
        }
    }];;
}

- (void)fetchGeopointsForIds:(NSArray *)guestIds completion:(void (^)(NSDictionary *userLocations))completionBlock
{
    PFQuery *geopointsQuery = [PFUser query];
    [geopointsQuery whereKey:@"fbID" containedIn:guestIds];
    //[geopointsQuery whereKey:@"Allowed" equalTo:@"YES"];
    [geopointsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSMutableDictionary *userLocations = [[NSMutableDictionary alloc] init];
        for (PFUser *friend in objects) {
            userLocations[friend[@"fbID"]] = friend[@"location"];
        }
        completionBlock([[NSDictionary alloc] initWithDictionary:userLocations]);
    }];
}

- (void)logInWithCompletion:(void (^)())completionBlock
{
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[@"user_events", @"friends_events", @"create_event", @"rsvp_event"];
    
    // Login PFUser using facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        
        if (!user) {
            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error"
                                                                message:@"The user cancelled the Facebook login."
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
            if ([[PFUser currentUser] isNew]) {
                
                PFGeoPoint *geoPoint = [PFGeoPoint geoPoint];
                [[PFUser currentUser] setObject:geoPoint forKey:@"location"];
                
                FBRequest *idRequest = [FBRequest requestForGraphPath:@"me?fields=id"];
                [idRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    
                    if (error) {
                        
                        UIAlertView *alert = [[UIAlertView alloc]
                                              initWithTitle:@"Could Not Connect To Facebook"
                                              message:nil
                                              delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Dismiss", nil];
                        [alert show];
                        
                    } else {
                        
                        [[PFUser currentUser] setObject:result[@"id"] forKey:facebookID];
                        
                    }
                }];
                
                PFObject *tracking = [PFObject objectWithClassName:@"TrackingObject"];
                [[PFUser currentUser] setObject:tracking forKey:trackingObject];
                
                [[PFUser currentUser] saveInBackground];
                
            }
            
            [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
            [[PFInstallation currentInstallation] saveInBackground];
            
            completionBlock();
        }
        
    }];
}

- (void)logOutWithCompletion:(void (^)())completionBlock
{
    [[PFFacebookUtils session] closeAndClearTokenInformation];
    [PFUser logOut];
    [_locationManager stopUpdatingLocation];
    [_locationManager stopMonitoringSignificantLocationChanges];
    completionBlock();
}

#pragma mark Location tracking

- (void)fetchLocationWithCompletion:(void (^)(CLLocation *))completionBlock
{
    
    if (!completionBlock) {
        NSLog(@"No completion block for fetching location!");
        return;
    }
    
    self.locationCompletionBlock = completionBlock;
    [self.locationManager startUpdatingLocation];
    
}

- (void)startTrackingMyLocation
{
    if (![self isLoggedIn] || ![self verifyTrackingAllowed]) {
        return;
    }
    
    [_locationManager startUpdatingLocation];
}

- (BOOL) verifyTrackingAllowed {
    PFObject *trackingObj = [[PFUser currentUser] objectForKey:trackingObject];
    for (NSString *key in [trackingObj allKeys]) {
        NSString * object = [NSString stringWithFormat:@"%@", trackingObj[key]];
        if ([object isEqualToString:allowed] || [trackingObj[key] isEqualToString:anonymous]) {
            return  YES;
        }
    }
    [_locationManager stopUpdatingLocation];
    return NO;
}
- (void) changePermissionForEvent: (NSString *) eventId identity: (NSString *) identity {
    PFObject *tracking = [[PFUser currentUser] objectForKey:trackingObject];
    [tracking setObject:identity forKey:[NSString stringWithFormat:@"E%@", eventId]];    
    [self startTrackingMyLocation];
    [[PFUser currentUser] saveInBackground];
}

#pragma mark Facebook Request
- (void)fetchEventListDataWithCompletion:(void (^)(NSArray *hostEvents, NSArray *guestEvents, NSArray* maybeAttendingEvents, NSArray *noReplyEvents))completionBlock
{
    
    FBRequest *request = [FBRequest requestForGraphPath:
                          @"me?fields=events.limit(1000).fields(id,name,admins.fields(id,name),"
                          @"cover,rsvp_status,start_time),id"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
        } else {
            
            if (!self.myId) {
                // Store myId locally and in parse, if it's not there already
                _myId = result[@"id"];
                [[PFUser currentUser] setObject:_myId forKey:facebookID];
                [[PFUser currentUser] saveInBackground];
            }
            
            FBGraphObject *fbGraphObj = (FBGraphObject *)result;
            NSArray *eventArray = fbGraphObj[@"events"][@"data"];
            
            NSMutableArray *hostEvents = [[NSMutableArray alloc] init];
            NSMutableArray *attendingEvents = [[NSMutableArray alloc] init];
            NSMutableArray *maybeEvents = [[NSMutableArray alloc] init];
            
            for (FBGraphObject *event in eventArray) {
                
                [event fixEventCoverPhoto];
                
                // Checking if maybe (host cannot be maybe)
                NSString *rsvpStatus = event[@"rsvp_status"];
                if ([rsvpStatus isEqualToString:@"unsure"]) {
                    [maybeEvents insertObject:event atIndex:0];
                    continue;
                }
            
                // Checking if host or just attending
                NSArray *adminArray = event[@"admins"][@"data"];
                BOOL isHost = NO;
                for (FBGraphObject *adminData in adminArray) {
                    if ([adminData[@"id"] isEqualToString:_myId]) {
                        isHost = YES;
                        break;
                    }
                }
                
                if (isHost == YES) {
                    [hostEvents insertObject:event atIndex:0];
                } else {
                    [attendingEvents insertObject:event atIndex:0];
                }
                
            }
            
            //TODO: break this into a separate method completely
            FBRequest *noReplyRequest = [FBRequest requestForGraphPath:
                                         @"me?fields=events.limit(1000).type(not_replied).fields(id,name,"
                                         @"cover,rsvp_status,start_time),id"];
            [noReplyRequest startWithCompletionHandler:^(FBRequestConnection *connection,
                                                         id result,
                                                         NSError *error){
                if (error) {
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                                    message:error.localizedDescription
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                    
                } else {
                    
                    FBGraphObject *fbGraphObj = (FBGraphObject *)result;
                    NSArray *noReplyArray = fbGraphObj[@"events"][@"data"];
                    
                    NSMutableArray *noReplyEvents = [[NSMutableArray alloc] init];
                    for (FBGraphObject *event in noReplyArray)
                    {
                        [event fixEventCoverPhoto];
                        [noReplyEvents insertObject:event atIndex:0];
                    }
                    
                completionBlock(hostEvents, attendingEvents, maybeEvents, noReplyEvents);
                }
            }];
        }
    }];
}

- (void)fetchEventDetailsWithEvent:(NSString *)eventId completion:(void (^)(NSDictionary *eventDetails))completionBlock
{
    NSString *graphPath = [NSString stringWithFormat:@"%@?fields=location,description,venue,owner,privacy,attending.fields(id,name,picture.height(100).width(100))", eventId];
    FBRequest *request = [FBRequest requestForGraphPath:graphPath];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error getting event details!"
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            
        }
        else {
            
            if (completionBlock) {
                completionBlock((NSDictionary *)result);
            }
            
        }
        
    }];
    
}

- (void)fetchPartialEventDetailsForNewEvent:(NSString *)eventId completion:(void (^)(NSDictionary *eventDetails))completionBlock
{
    NSString *graphPath = [NSString stringWithFormat:
                                  @"%@?fields=id,name,admins.fields(id,name),cover,start_time", eventId];
    
    FBRequest *request = [FBRequest requestForGraphPath:graphPath];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (error) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error getting event details!"
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            
        } else {
            
            [result fixEventCoverPhoto];
            
            if (completionBlock) {
                completionBlock((NSDictionary *)result);
            }
            
        }
        
    }];
}

#pragma mark Parse Request
- (void)fetchGeopointsForIds:(NSArray *)guestIds eventId:(NSString *)eventId completion:(void (^)(NSDictionary *userLocations))completionBlock
{
    PFQuery *geopointsQuery = [PFUser query];
//    NSMutableDictionary *userLocations = [[NSMutableDictionary alloc] init];
    [geopointsQuery whereKey:facebookID containedIn:guestIds];
    [geopointsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSMutableDictionary *userLocations = [[NSMutableDictionary alloc] init];
        for (PFUser *friend in objects) {
            
            [userLocations setObject:friend[@"location"] forKey:friend[facebookID]];
        }
        
        [_trackingCount setObject:[NSNumber numberWithInt:objects.count] forKey:eventId];
        completionBlock([[NSDictionary alloc] initWithDictionary:userLocations]);
    }];
}

#pragma mark Edit Event Details
- (void)inviteFriendsToEvent:(NSString *)eventId withFriends:(NSArray *)friendIdArray completion:(void (^)())completionBlock
{
    NSString *friendIdArrayString = [friendIdArray componentsJoinedByString:@","];
    
    NSDictionary *requestParams = @{ @"users":friendIdArrayString };
    NSString *graphPath = [NSString stringWithFormat:@"%@/invited", eventId];
    
    FBRequest *request = [FBRequest requestWithGraphPath:graphPath parameters:requestParams HTTPMethod:@"POST"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (error) {
            
            UIAlertView *alertView;
            
            alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                   message:error.localizedDescription
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
            
            [alertView show];
            
        } else {
            
            if (completionBlock)
                completionBlock();
            
        }
        
    }];
}

- (void)changeRSVPStatusToEvent:(NSString *)eventId newStatus:(NSString *)status completion:(void (^)())completionBlock
{
    NSString *urlStatusString;
    if ([status isEqualToString:@"Going"]) {
        urlStatusString = @"attending";
    } else if ([status isEqualToString:@"Maybe"]) {
        urlStatusString = @"maybe";
    } else if ([status isEqualToString:@"Not Going"]) {
        urlStatusString = @"declined";
    }
    else {
        return;
    }
    NSString *graphPath = [NSString stringWithFormat:@"%@/%@/%@", eventId, urlStatusString, _myId];

    FBRequest *request = [FBRequest requestWithGraphPath:graphPath parameters:nil HTTPMethod:@"POST"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (error) {
            
            UIAlertView *alertView;
            alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                   message:error.localizedDescription
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
            
            [alertView show];
            
        } else {
            NSLog(@"%@",result);
            if (completionBlock)
                completionBlock();
            
        }
        
    }];
}


- (void)createEventWithParameters:(NSDictionary *)eventParameters
                       completion:(void (^)(NSString *newEventId))completionBlock;
{
    NSString *graphPath = [NSString stringWithFormat:@"%@/events", self.myId];
    FBRequest *newEventRequest = [FBRequest requestWithGraphPath:graphPath
                                                      parameters:eventParameters
                                                      HTTPMethod:@"POST"];
    [newEventRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (error) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            
        } else {
            
            if (completionBlock) {
                completionBlock((NSString *)result[@"id"]);
            }
            
        }
    }];
}

#pragma mark Push Notifications
-(void) notifyUsersWithCompletion:(NSString *)eventId guestArray:(NSArray*)guestArray completion:(void (^)())completionBlock
{
    NSMutableArray *guestIds = [[NSMutableArray alloc] init];
    
    for (id obj in guestArray)
    {
        [guestIds addObject:obj[@"id"]];
    }
    
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:facebookID containedIn:guestIds];
    
    PFQuery *installationQuery = [PFInstallation query];
    [installationQuery whereKey:@"user" matchesQuery:userQuery];
    
    PFPush *trackingAllowedNotification = [[PFPush alloc] init];
    [trackingAllowedNotification setQuery:installationQuery];
    
    FBRequest *request = [FBRequest requestForGraphPath:[NSString stringWithFormat:@"%@?fields=name",eventId]];
    
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSString *eventName = result[@"name"];
        NSDictionary *eventIdDict = @{@"eventId": eventId,@"eventName":eventName};

        [trackingAllowedNotification setData:eventIdDict];
        
        [trackingAllowedNotification sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"push succeded");
            }
            if (completionBlock) {
                completionBlock();
            }
        }];

    }];
}

@end
