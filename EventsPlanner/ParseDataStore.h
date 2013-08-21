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

extern BOOL const isDemo;
extern NSString * const allowed;
extern NSString * const anonymous;
extern NSString * const notAllowed;

extern NSString * const kParseUserNameKey;
extern NSString * const facebookID;
extern NSString * const locationKey;

extern NSString * const kTimeKey;
extern NSString * const kLocationData;
extern NSString * const kHostEventsKey;
extern NSString * const kAttendingEventsKey;
extern NSString * const kMaybeEventsKey;
extern NSString * const kUnsureEventKey;
extern NSString * const kNoReplyEventsKey;
extern NSString * const kDeclinedEventsKey;

@interface ParseDataStore : NSObject

@property (readonly, nonatomic) BOOL isLoggedIn;
@property BOOL isTracking;
@property (strong, nonatomic) NSString *myId;
@property (readonly, nonatomic, strong) NSMutableDictionary *trackingCount;

+ (ParseDataStore *)sharedStore;

- (void)logInWithCompletion:(void (^)())completionBlock;
- (void)logOutWithCompletion:(void (^)())completionBlock;

- (void)fetchLocationWithCompletion:(void (^)(CLLocation *location))completionBlock;

- (void)startTrackingMyLocationIfAllowed;
- (void)stopTrackingMyLocation;
- (void)changePermissionForEvent:(NSString *)eventId identity:(NSString *)identity completion:(void (^)())completionBlock;
- (void)fetchPermissionForEvent:(NSString *)eventId
                     completion:(void (^)(NSString *identity))completionBlock;

- (void)setTrackingStatus:(BOOL)isTracking event:(NSString *)eventId completion:(void (^)())completion;
- (void)fetchTrackingStatusForEvent:(NSString *)eventId completion:(void (^)(BOOL isTracking))completionBlock;

- (void)fetchEventListDataForListKey:(NSString *)listKey completion:(void (^)(NSArray *eventsList))completionBlock;
- (void)fetchEventDetailsForEvent:(NSString *)eventId useCache:(BOOL)usesCache completion:(void (^)(NSDictionary *eventDetails))completionBlock;

- (void)fetchAllEventListDataWithCompletion:(void (^)(NSArray *activeHostEvents,
                                                      NSArray *activeGuestEvents,
                                                      NSArray *hostEvents,
                                                      NSArray *guestEvents,
                                                      NSArray *maybeAttendingEvents,
                                                      NSArray *noReplyEvents))completionBlock;
- (void)fetchProfilePictureForUser:(NSString *)fbId completion:(void (^)(UIImage *profilePic))completionBlock;

- (void)fetchPartialEventDetailsForNewEvent:(NSString *)eventId completion:(void (^)(NSDictionary *eventDetails))completionBlock;

- (void)fetchFriendsOfEvent:(NSString *)eventId completion:(void (^)(NSArray *friendIds, NSString *eventName))completionBlock;
- (void)fetchUsersForEvent:(NSString *)eventId completion:(void (^)(NSArray *allowedUsers, NSArray *anonUsers))completionBlock;

- (void)inviteFriendsToEvent:(NSString *)eventId
                 withFriends:(NSArray *)friendIdArray
                  completion:(void (^)())completionBlock;
- (void)changeRSVPStatusToEvent:(NSString *)eventId
                      oldStatus:(NSString *)oldStatus
                      newStatus:(NSString *)status
                     completion:(void (^)())completionBlock;

- (void)pushNotificationsToGuestsOfEvent:(NSString *)eventId completion:(void (^)(NSArray *friendIdsArray))completionBlock;
- (void)pushEventCancelledToGuestsOfEvent:(NSString *)eventId completion:(void (^)())completionBlock;

- (void)createEventWithParameters:(NSDictionary *)eventParameters
                       completion:(void (^)(NSString *newEventId))completionBlock;

- (void)editEventWithParameters:(NSDictionary *)eventParameters eventId:(NSString *)eventId
                     completion:(void (^)())completionBlock;

- (void)deleteEvent:(NSString *)eventId completion:(void (^)())completionBlock;
;

@end