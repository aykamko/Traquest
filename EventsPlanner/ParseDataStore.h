//
//  ParseDataStore.h
//  EventsPlanner
//
//  Created by Anupa Murali on 8/2/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <Parse/PFUser.h>

extern NSString * const facebookID;
extern NSString * const locationKey;
extern NSString * const trackingData;

@interface ParseDataStore : NSObject

@property (readonly, nonatomic) BOOL isLoggedIn;
@property (strong, nonatomic) NSString *myId;

+ (ParseDataStore *)sharedStore;

- (void)logInWithCompletion:(void (^)())completionBlock;
- (void)logOutWithCompletion:(void (^)())completionBlock;

- (void)fetchLocationWithCompletion:(void (^)(CLLocation *location))completionBlock;

- (void)startTrackingMyLocation;
- (void)stopTrackingMyLocation;
- (void)allowTrackingForEvent:(NSString *)eventId identity:(BOOL)identity;
- (void)disallowTrackingForEvent:(NSString *)eventId;

- (void)fetchEventListDataWithCompletion:(void (^)(NSArray *hostEvents, NSArray *guestEvents,
    NSArray* maybeAttendingEvents, NSArray *noReplyEvents))completionBlock;

- (void)fetchEventDetailsWithEvent:(NSString *)eventId completion:(void (^)(NSDictionary *eventDetails))completionBlock;
- (void)fetchPartialEventDetailsForNewEvent:(NSString *)eventId completion:(void (^)(NSDictionary *eventDetails))completionBlock;

- (void)fetchGeopointsForIds:(NSArray *)guestIds eventId:(NSString *)eventId completion:(void (^)(NSDictionary *userLocations))completionBlock;

- (void)inviteFriendsToEvent:(NSString *)eventId withFriends:(NSArray *)friendIdArray completion:(void (^)())completionBlock;
- (void)changeRSVPStatusToEvent:(NSString *)eventId newStatus:(NSString *)status completion:(void (^)())completionBlock;

- (void)notifyUsersWithCompletion:(NSString *)eventId guestArray:(NSArray *)guestArray completion:(void (^)())completionBlock;

- (void)createEventWithParameters:(NSDictionary *)eventParameters completion:(void (^)(NSString *newEventId))completionBlock;

@end