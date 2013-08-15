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

extern NSString * const allowed;
extern NSString * const anonymous;
extern NSString * const notAllowed;

extern NSString * const facebookID;
extern NSString * const locationKey;
extern NSString * const trackingObject;

extern NSString * const kHostEventsKey;
extern NSString * const kAttendingEventsKey;
extern NSString * const kMaybeEventsKey;
extern NSString * const kUnsureEventKey;
extern NSString * const kNoReplyEventsKey;
extern NSString * const kDeclinedEventsKey;

@interface ParseDataStore : NSObject

@property (readonly, nonatomic) BOOL isLoggedIn;
@property (strong, nonatomic) NSString *myId;
@property (readonly, nonatomic, strong) NSMutableDictionary *trackingCount;

+ (ParseDataStore *)sharedStore;

- (void)logInWithCompletion:(void (^)())completionBlock;
- (void)logOutWithCompletion:(void (^)())completionBlock;

- (void)fetchLocationWithCompletion:(void (^)(CLLocation *location))completionBlock;

- (void)startTrackingMyLocationIfAllowed;
- (BOOL)verifyTrackingAllowed;
- (void)changePermissionForEvent:(NSString *)eventId identity:(NSString *)identity;

- (void)setTrackingStatus:(BOOL)isTracking event:(NSString *)eventId;
- (void)fetchTrackingStatusForEvent:(NSString *)eventId completion:(void (^)(BOOL isTracking))completionBlock;

- (void)fetchEventListDataForListKey:(NSString *)listKey completion:(void (^)(NSArray *eventsList))completionBlock;
- (void)fetchEventDetailsForEvent:(NSString *)eventId completion:(void (^)(NSDictionary *eventDetails))completionBlock;
- (void)fetchAllEventListDataWithCompletion:(void (^)(NSArray *activeHostEvents,
                                                      NSArray *activeGuestEvents,
                                                      NSArray *hostEvents,
                                                      NSArray *guestEvents,
                                                      NSArray *maybeAttendingEvents,
                                                      NSArray *noReplyEvents))completionBlock;

- (void)fetchPartialEventDetailsForNewEvent:(NSString *)eventId completion:(void (^)(NSDictionary *eventDetails))completionBlock;

- (void)fetchGeopointsForIds:(NSArray *)guestIds eventId:(NSString *)eventId completion:(void (^)(NSDictionary *userLocations))completionBlock;

- (void)inviteFriendsToEvent:(NSString *)eventId
                 withFriends:(NSArray *)friendIdArray
                  completion:(void (^)())completionBlock;
- (void)changeRSVPStatusToEvent:(NSString *)eventId
                      oldStatus:(NSString *)oldStatus
                      newStatus:(NSString *)status
                     completion:(void (^)())completionBlock;

- (void)notifyUsersWithCompletion:(NSString *)eventId guestArray:(NSArray *)guestArray completion:(void (^)())completionBlock;

- (void)createEventWithParameters:(NSDictionary *)eventParameters completion:(void (^)(NSString *newEventId))completionBlock;

@end