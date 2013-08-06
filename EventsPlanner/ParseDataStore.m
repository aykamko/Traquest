//
//  ParseDataStore.m
//  EventsPlanner
//
//  Created by Anupa Murali on 8/2/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "ParseDataStore.h"
#import "UIImage+ImageCrop.h"

@interface ParseDataStore () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *userPastLocations;
@property (strong, nonatomic) CLLocation *currentLocation;

@property (strong, nonatomic) NSString *myId;

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
    [_userPastLocations addObject:geoPoint];
    [[PFUser currentUser] saveInBackground];
}

-(void)fetchLocationDataForIds: (NSSet *) userIds WithWithCompletion:(void (^)(NSMutableDictionary *userLocations)) completionBlock{
    
    NSMutableDictionary *userLocations = [[NSMutableDictionary alloc] init];
    
    PFQuery *trackingQuery = [PFUser query];
    [trackingQuery whereKey: @"fbID" containedIn:[userIds allObjects]];
    [trackingQuery whereKey:@"trackingAllowed" equalTo:@"YES"];
    NSArray *trackingAllowed = [trackingQuery findObjects];
    
    for (PFUser *friend in trackingAllowed)
    {
        [userLocations setObject:friend[@"location"] forKey:friend[@"fbID"]];
    }
    
    completionBlock(userLocations);
}

-(void)logOutWithCompletion:(void (^)())completionBlock{
    [[PFFacebookUtils session]closeAndClearTokenInformation];
    [PFUser logOut];
    completionBlock();
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





- (void)fetchEventListDataWithCompletion:(void (^)(NSArray *hostEvents, NSArray *guestEvents))completionBlock
{
    
    FBRequest *request = [FBRequest requestForGraphPath:
                          @"me?fields=events.limit(1000).fields(name,admins.fields(id,name),"
                          @"location,cover,owner,"
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
            _myId = result[@"id"];
            
            // Save the logged in user's Facebook ID to parse
            [[PFUser currentUser] setObject:_myId forKey:@"fbID"];
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
                CGSize defaultCoverSize = {640,320};
                if(!event[@"cover"]) {
                    UIImage *mainImage = [UIImage imageNamed:@"eventCoverPhoto.png"];
                    UIImage *coloring = [UIImage imageWithBackground:[UIColor colorWithWhite:0 alpha:0.3] size:defaultCoverSize];
                    UIImage *imageWithBackground = [UIImage overlayImage:coloring overImage:mainImage];
                    UIImage *gradientImage = [UIImage imageWithGradient:defaultCoverSize withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6] withColor2:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] vertical:NO];
                    event[@"cover"] = [UIImage overlayImage:gradientImage overImage:imageWithBackground];
                } else {
                    UIImage *mainImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:event[@"cover"][@"source"]]]];
                    UIImage *gradientImage = [UIImage imageWithGradient:defaultCoverSize withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6] withColor2:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] vertical:NO];
                    event[@"cover"] = [UIImage overlayImage:gradientImage overImage:mainImage];
                }
                
            }
            
            
            completionBlock(hostEvents, guestEvents);
        }
    }];
}
    
-(void) notifyUsersWithCompletion:(void (^)(NSArray *))completionBlock
{
    
}

- (void)event:(NSString *)eventId inviteFriends:(NSArray *)freindIdArray completion:(void (^)())completionBlock
{
    NSString *friendIdArrayString = [freindIdArray componentsJoinedByString:@","];
    
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

- (void)event:(NSString *)eventId changeRsvpStatusTo:(NSString *)status completion:(void (^)())completionBlock
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

@end
