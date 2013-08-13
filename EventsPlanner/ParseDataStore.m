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
#import "EventsListController.h"

#pragma mark Parse String Keys

NSString * const allowed = @"allowed";
NSString * const anonymous = @"anonymous";
NSString * const notAllowed = @"notAllowed";

NSString * const locationKey = @"location";
NSString * const facebookID = @"fbID";
NSString * const trackingObject = @"trackingDictionary";

NSString * const kHostEventsKey = @"host";
NSString * const kAttendingEventsKey = @"attending";
NSString * const kMaybeEventsKey = @"maybe";
NSString * const kUnsureEventKey = @"unsure";
NSString * const kNoReplyEventsKey = @"not_replied";
NSString * const kDeclinedEventsKey = @"declined";

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

- (void)fetchLocationDataForIds: (NSDictionary *) guestDetails
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

#pragma mark Caching data


// All events lists
- (BOOL)saveAllEventsLists:(NSDictionary *)dictOfEventsListsByKey
{
    BOOL allSucceeded = YES;
    
    NSArray *eventsListKeyArray = @[kHostEventsKey, kAttendingEventsKey, kMaybeEventsKey, kNoReplyEventsKey];
    for (NSString *key in eventsListKeyArray) {
        
        BOOL succeeded = [self saveEventsList:dictOfEventsListsByKey[key] forKey:key];
        if (succeeded == NO) {
            allSucceeded = NO;
        }
        
    }
    
    return allSucceeded;
}

- (NSDictionary *)loadAllEventsListsFromCacheAsKeyedDictionary
{
    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
    
    NSArray *eventsListKeyArray = @[kHostEventsKey, kAttendingEventsKey, kMaybeEventsKey, kNoReplyEventsKey];
    for (NSString *key in eventsListKeyArray) {
        NSArray *eventsList = [self loadEventsListForKey:key];
        [resultDictionary addEntriesFromDictionary:@{ key:eventsList }];
    }
    
    return resultDictionary;
}

- (void)setDateOfAllEventsLists
{
    NSArray *eventsListByKey = @[kHostEventsKey, kMaybeEventsKey, kAttendingEventsKey, kNoReplyEventsKey];
    for (NSString *key in eventsListByKey) {
        [self setDateOfCacheForEventsListOfKey:key];
    }
}

- (NSDate *)dateOfOldestCache
{
    NSArray *eventsListByKey = @[kHostEventsKey, kMaybeEventsKey, kAttendingEventsKey, kNoReplyEventsKey];
    NSDate *oldestCacheDate = [NSDate date];
    for (NSString *key in eventsListByKey) {
        NSDate *currentCacheDate = [self dateOfCacheForEventsListOfKey:key];
        if ([currentCacheDate compare:oldestCacheDate] == NSOrderedAscending) {
            oldestCacheDate = currentCacheDate;
        }
    }
    return oldestCacheDate;
}

// Specific events list
- (NSString *)archivePathForEventsListWithKey:(NSString *)eventsListKey
{
    NSArray *cacheDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [cacheDirectories firstObject];
    
    NSString *appendedPath = [NSString stringWithFormat:@"%@_eventsList.archive", eventsListKey];
    
    return [cacheDirectory stringByAppendingPathComponent:appendedPath];
}

- (BOOL)saveEventsList:(NSArray *)eventsList forKey:(NSString *)eventsListKey
{
    return [NSKeyedArchiver archiveRootObject:eventsList
                                       toFile:[self archivePathForEventsListWithKey:eventsListKey]];
}

- (NSArray *)loadEventsListForKey:(NSString *)eventsListKey
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self archivePathForEventsListWithKey:eventsListKey]];
}


- (NSDate *)dateOfCacheForEventsListOfKey:(NSString *)eventsListKey
{
    NSString *cacheKey = [NSString stringWithFormat:@"%@_eventsListCacheDate", eventsListKey];
    return [[NSUserDefaults standardUserDefaults] objectForKey:cacheKey];
}

- (void)setDateOfCacheForEventsListOfKey:(NSString *)eventsListKey
{
    NSString *cacheKey = [NSString stringWithFormat:@"%@_eventsListCacheDate", eventsListKey];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:cacheKey];
}

// Event Details
- (NSString *)eventDetailsArchivePathForEvent:(NSString *)eventId
{
    NSArray *cacheDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [cacheDirectories firstObject];
    
    return [cacheDirectory stringByAppendingPathExtension:[NSString stringWithFormat:@"%@.archive", eventId]];
}

- (BOOL)saveEventDetails:(NSDictionary *)eventDetails event:(NSString *)eventId
{
    return [NSKeyedArchiver archiveRootObject:eventDetails
                                       toFile:[self eventDetailsArchivePathForEvent:eventId]];
}

- (NSDictionary *)fetchEventDetailsFromCacheForEvent:(NSString *)eventId
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self eventDetailsArchivePathForEvent:eventId]];
}

- (NSString *)cacheDateObjectKeyForEvent:(NSString *)eventId
{
    return [NSString stringWithFormat:@"%@_cacheDate", eventId];
}

- (NSDate *)eventDetailsCacheDateForEvent:(NSString *)eventId
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:[self cacheDateObjectKeyForEvent:eventId]];
}

- (void)setEventDetailsCacheDateForEvent:(NSString *)eventId
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:[self cacheDateObjectKeyForEvent:eventId]];
}


#pragma mark Facebook Request
- (void)fetchAllEventListDataWithCompletion:(void (^)(NSArray *hostEvents,
                                                      NSArray *guestEvents,
                                                      NSArray *maybeAttendingEvents,
                                                      NSArray *noReplyEvents))completionBlock
{
    
    // Get cached data if not too old
    NSDate *oldestCacheDate = [self dateOfOldestCache];
    if (oldestCacheDate) {
        NSTimeInterval cacheAge = [oldestCacheDate timeIntervalSinceNow];
        if (cacheAge > -60 * 10) {
            NSDictionary *savedEventsList = [self loadAllEventsListsFromCacheAsKeyedDictionary];
            if (savedEventsList) {
                if (!self.myId) {
                    self.myId = [[NSUserDefaults standardUserDefaults] objectForKey:@"myFbId"];
                }
                completionBlock(savedEventsList[kHostEventsKey],
                                savedEventsList[kAttendingEventsKey],
                                savedEventsList[kMaybeEventsKey],
                                savedEventsList[kNoReplyEventsKey]);
                return;
            }
        }
    }
    
    FBRequest *request = [FBRequest requestForGraphPath:
                          @"me?fields=events.limit(1000).fields(id,name,admins.fields(id,name),"
                          @"cover,rsvp_status,start_time),id"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error getting events lists!"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
        } else {
            
            if (!self.myId) {
                // Store myId locally and in parse, if it's not there already
                self.myId = result[@"id"];
                [[NSUserDefaults standardUserDefaults] setObject:self.myId forKey:@"myFbId"];
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
            
            FBRequest *noReplyRequest = [FBRequest requestForGraphPath:
                                         @"me?fields=events.limit(1000).type(not_replied).fields(id,name,"
                                         @"cover,rsvp_status,start_time)"];
            [noReplyRequest startWithCompletionHandler:^(FBRequestConnection *connection,
                                                         id result,
                                                         NSError *error){
                if (error) {
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error getting no reply events!"
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
                    
                    [self setDateOfAllEventsLists];
                    [self saveAllEventsLists:@{ kHostEventsKey: hostEvents,
                                                kAttendingEventsKey: attendingEvents,
                                                kMaybeEventsKey: maybeEvents,
                                                kNoReplyEventsKey: noReplyEvents }];
                    completionBlock(hostEvents, attendingEvents, maybeEvents, noReplyEvents);
                    
                }
            }];
        }
    }];
}

- (void)fetchEventListDataForListKey:(NSString *)listKey completion:(void (^)(NSArray *eventsList))completionBlock
{
    NSString *graphPath = @"me?fields=events.limit(1000).type(%@).fields(id,name,"
                          @"cover,admins.fields(id,name),rsvp_status,start_time)";
    NSString *filterKey;
    if ([listKey isEqualToString:kHostEventsKey]) {
        filterKey = @"attending";
    } else if ([listKey isEqualToString:kAttendingEventsKey]) {
        filterKey = @"attending";
    } else if ([listKey isEqualToString:kMaybeEventsKey] || [listKey isEqualToString:kUnsureEventKey]) {
        filterKey = @"maybe";
    } else if ([listKey isEqualToString:kNoReplyEventsKey]) {
        filterKey = @"not_replied";
    } else {
        return;
    }
    
    graphPath = [NSString stringWithFormat:graphPath, filterKey];
    
    FBRequest *request = [FBRequest requestForGraphPath:graphPath];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error){
        
        if (error) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error getting event list!"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
        } else {
            
            FBGraphObject *fbGraphObj = (FBGraphObject *)result;
            NSArray *eventArray = fbGraphObj[@"events"][@"data"];
            
            NSMutableArray *specificEvents = [[NSMutableArray alloc] init];
            for (FBGraphObject *event in eventArray)
            {
                [event fixEventCoverPhoto];
                
                if ([listKey isEqualToString:kMaybeEventsKey] ||
                    [listKey isEqualToString:kUnsureEventKey] ||
                    [listKey isEqualToString:kNoReplyEventsKey]) {
                    
                    [specificEvents insertObject:event atIndex:0];
                    continue;
                    
                }
                
                NSArray *adminArray = event[@"admins"][@"data"];
                BOOL isHost = NO;
                for (FBGraphObject *adminData in adminArray) {
                    if ([adminData[@"id"] isEqualToString:_myId]) {
                        isHost = YES;
                        break;
                    }
                }
                
                if ([listKey isEqualToString:kHostEventsKey] && isHost == YES) {
                    [specificEvents insertObject:event atIndex:0];
                } else if ([listKey isEqualToString:kAttendingEventsKey] && isHost == NO) {
                    [specificEvents insertObject:event atIndex:0];
                }
                
            }
            
            [self setDateOfCacheForEventsListOfKey:listKey];
            [self saveEventsList:specificEvents forKey:listKey];
            
            if (completionBlock) {
                completionBlock(specificEvents);
            }
        }
        
    }];
}
- (void)fetchEventDetailsForEvent:(NSString *)eventId completion:(void (^)(NSDictionary *eventDetails))completionBlock
{
    // Get cached data is not too old
    NSDate *eventDetailsCacheDate = [self eventDetailsCacheDateForEvent:eventId];
    if (eventDetailsCacheDate) {
        NSTimeInterval cacheAge = [eventDetailsCacheDate timeIntervalSinceNow];
        if (cacheAge > (-60 * 5)) {
            NSDictionary *savedEventDetails = [self fetchEventDetailsFromCacheForEvent:eventId];
            if (savedEventDetails) {
                NSLog(@"cached details");
                completionBlock(savedEventDetails);
                return;
            }
        }
    }
    
    NSString *graphPath = [NSString stringWithFormat:
                           @"%@?fields=location,description,venue,owner,privacy,"
                           @"attending.fields(id,name,picture.height(100).width(100))", eventId];
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
            
            [self setEventDetailsCacheDateForEvent:eventId];
            [self saveEventDetails:(NSDictionary *)result event:eventId];
            
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

- (void)changeRSVPStatusToEvent:(NSString *)eventId
                      oldStatus:(NSString *)oldStatus
                      newStatus:(NSString *)newStatus
                     completion:(void (^)())completionBlock
{
    
    NSString *graphPath = [NSString stringWithFormat:@"%@/%@/%@", eventId, newStatus, self.myId];

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
            
            [self fetchEventListDataForListKey:oldStatus completion:^(NSArray *eventsList) {
                [[EventsListController sharedListController] refreshTableViewForEventsListKey:oldStatus
                                                                                newEventsList:eventsList
                                                                  endRefreshForRefreshControl:nil];
            }];
            [self fetchEventListDataForListKey:newStatus completion:^(NSArray *eventsList) {
                [[EventsListController sharedListController] refreshTableViewForEventsListKey:newStatus
                                                                                newEventsList:eventsList
                                                                  endRefreshForRefreshControl:nil];
            }];
            
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
