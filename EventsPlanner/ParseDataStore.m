//
//  ParseDataStore.m
//  EventsPlanner
//
//  Created by Anupa Murali on 8/2/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "ParseDataStore.h"
#import "UIImage+ImageCrop.h"

#pragma mark Parse String Keys

NSString * const location = @"location";
NSString * const facebookID = @"fbID";
NSString * const trackingData = @"trackingDictionary";

// = facebookID;

@interface ParseDataStore () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *userPastLocations;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) NSMutableArray *allAttendingFriends;


@end

@implementation ParseDataStore

#pragma mark -Class Methods

- (id)init
{
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        CLLocationDistance distance = 50.0;
        [_locationManager setDistanceFilter:distance];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
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

- (void)startTrackingMyLocation
{
    if (![self isLoggedIn]) {
        return;
    }
    
    _locationManager = [[CLLocationManager alloc] init];
    
    [_locationManager setDelegate:self];
    [_locationManager startMonitoringSignificantLocationChanges];
    
  //  [[PFUser currentUser] setObject:@"YES" forKey:@"trackingAllowed"];
    
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
    [_userPastLocations addObject:geoPoint];
    [[PFUser currentUser] saveInBackground];
}

-(void)fetchLocationDataForIds: (NSDictionary *) guestDetails
{    
    PFQuery *trackingQuery = [PFUser query];
    [trackingQuery whereKey: @"fbID" containedIn:[guestDetails allKeys]];
    //[trackingQuery whereKey:@"trackingAllowed" equalTo:@"YES"];
    
    NSArray *users = [trackingQuery findObjects];
    for (PFUser *friend in users) //for every user that allows tracking
    {
        NSString *friendID = friend[@"fbID"];
        guestDetails[friendID][@"location"] = friend[@"location"];
    }
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
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could Not Connect To Facebook" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                        [alert show];
                    }
                    else {
                        [[PFUser currentUser] setObject:result[@"id"] forKey:facebookID];
                    }
                    
                    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
                    NSData *data = [NSJSONSerialization dataWithJSONObject:mutableDictionary options:NSJSONWritingPrettyPrinted error:nil];
                    [[PFUser currentUser] setObject:data forKey:trackingData];
                    
                    [[PFUser currentUser] saveInBackground];
                    
                }];
            }
            completionBlock();
        }
        
    }];
}

- (void)logOutWithCompletion:(void (^)())completionBlock
{
    [[PFFacebookUtils session]closeAndClearTokenInformation];
    [PFUser logOut];
    [_locationManager stopUpdatingLocation];
    [_locationManager stopMonitoringSignificantLocationChanges];
    completionBlock();
}

#pragma mark Location tracking

- (void)startTrackingLocation
{
    BOOL locationDisabled = ![CLLocationManager locationServicesEnabled];
    if (![self isLoggedIn]||locationDisabled) {
        return;
    }
    
    NSArray *eventArray = [PFUser currentUser][@"trackingIsAllowed"];
    
    BOOL allowedEventsTracking = [[eventArray objectAtIndex: 0] count]>0;
    if (false){//!allowedEventsTracking) {
        return;
    }
    [_locationManager startUpdatingLocation];
}

-(void) stopTrackingLocation {
    [_locationManager stopMonitoringSignificantLocationChanges];
}

- (void) allowTrackingForEvent: (NSString *) eventId identity: (BOOL) identity {
    NSData *oldData = [[PFUser currentUser] objectForKey:trackingData];
    NSMutableDictionary *trackingDictionary = [NSJSONSerialization JSONObjectWithData:oldData options:NSJSONReadingMutableContainers error:nil];
    
    [trackingDictionary setObject:[NSNumber numberWithBool:identity] forKey:eventId];
    
    NSData *updatedData = [NSJSONSerialization dataWithJSONObject:trackingDictionary options:NSJSONWritingPrettyPrinted error:nil];
    [[PFUser currentUser] setObject:updatedData forKey:trackingData];
    
    [[PFUser currentUser] saveInBackground];
}

-(void) disallowTrackingForEvent:(NSString *)eventId {
    NSMutableDictionary *eventsDict = [NSJSONSerialization JSONObjectWithData:[PFUser currentUser][@"trackingDict"] options:NSJSONReadingMutableContainers error:nil];
    [eventsDict removeObjectForKey:eventId];
    
    if ([eventsDict count]==0) {
        [[ParseDataStore sharedStore] stopTrackingLocation];
    }
    
    NSData *eventData = [NSJSONSerialization dataWithJSONObject:eventsDict options:NSJSONWritingPrettyPrinted error:nil];
    [[PFUser currentUser] setObject:eventData forKey:@"trackingDict"];
    
    [[PFUser currentUser] saveInBackground];
}

#pragma mark Facebook Request
- (void)fetchEventListDataWithCompletion:(void (^)(NSArray *hostEvents, NSArray *guestEvents))completionBlock
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
            _myId = result[@"id"];
            
            // Save the logged in user's Facebook ID to parse
            [[PFUser currentUser] setObject:_myId forKey:facebookID];
            [[PFUser currentUser] saveInBackground];
            
            FBGraphObject *fbGraphObj = (FBGraphObject *)result;
            NSArray *eventArray = fbGraphObj[@"events"][@"data"];
            NSMutableArray *hostEvents = [[NSMutableArray alloc] init];
            NSMutableArray *guestEvents = [[NSMutableArray alloc] init];
            
            for (FBGraphObject *event in eventArray) {
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
                    [guestEvents insertObject:event atIndex:0];
                }
                
                CGSize defaultCoverSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 120);
                if(!event[@"cover"]) {
                    UIImage *mainImage = [UIImage imageNamed:@"eventCoverPhoto.png"];
                    UIImage *coloring = [UIImage imageWithBackground:[UIColor colorWithWhite:0 alpha:0.3]
                                                                size:defaultCoverSize];
                    UIImage *imageWithBackground = [UIImage overlayImage:coloring overImage:mainImage];
                    UIImage *gradientImage = [UIImage
                                              imageWithGradient:defaultCoverSize
                                              withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]
                                              withColor2:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2]
                                              vertical:NO];
                    event[@"cover"] = [UIImage overlayImage:gradientImage overImage:imageWithBackground];
                } else {
                    NSURL *imageURL = [NSURL URLWithString:event[@"cover"][@"source"]];
                    UIImage *mainImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                    UIImage *gradientImage = [UIImage
                                              imageWithGradient:defaultCoverSize
                                              withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]
                                              withColor2:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2]
                                              vertical:NO];
                    event[@"cover"] = [UIImage overlayImage:gradientImage overImage:mainImage];
                }
                
            }
            
            completionBlock(hostEvents, guestEvents);
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

#pragma mark Parse Request

- (void)fetchGeopointsForIds:(NSArray *)guestIds eventId:(NSString *)eventId completion:(void (^)(NSDictionary *userLocations))completionBlock
{
    PFQuery *geopointsQuery = [PFUser query];
//    NSMutableDictionary *userLocations = [[NSMutableDictionary alloc] init];
    [geopointsQuery whereKey:facebookID containedIn:guestIds];
    [geopointsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSMutableDictionary *userLocations = [[NSMutableDictionary alloc] init];
        for (PFUser *friend in objects) {
            
//            if (friend[@"trackingDict"][eventId])
//            {
            [userLocations setObject:friend[@"location"] forKey:friend[facebookID]];
//            }
        }
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
            
            if (completionBlock)
                completionBlock();
            
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
    
    PFQuery *userQuery  = [PFUser query];
    [userQuery whereKey:facebookID containedIn:guestIds];
    if(!completionBlock)
    {
        [userQuery findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
            for (PFUser *user in users)
            {
                [[PFInstallation currentInstallation] setObject:user forKey:@"user"];
                [[PFInstallation currentInstallation] save];
                

            }
            
            PFQuery *installationQuery = [PFInstallation query];
            [installationQuery whereKey:@"user" containedIn:users];
            PFPush *trackingAllowedNotification = [[PFPush alloc] init];
            [trackingAllowedNotification setQuery:installationQuery];
            [trackingAllowedNotification setMessage:@"Do you want to let the Host see where you are?"];
            [trackingAllowedNotification sendPushInBackground];
            
            if (completionBlock) {
                completionBlock();
            }
        }];

   }

}

@end
