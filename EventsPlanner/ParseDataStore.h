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
//#import "LocationDataStore.h"

@interface ParseDataStore : NSObject

@property (readonly, nonatomic) BOOL isLoggedIn;

+ (ParseDataStore *)sharedStore;

-(void)logInWithCompletion:(void (^)())completionBlock;
-(void)logOutWithCompletion: (void (^)())completionBlock;

-(void)fetchLocationDataForIds: (NSMutableDictionary *) guestDetails;
-(void)fetchEventListDataWithCompletion:(void (^)(NSArray *hostEvents, NSArray *guestEvents))completionBlock;

-(void)notifyUsersWithCompletion:(void(^)(NSArray *userLocations)) completionBlock;
-(void)startTrackingLocation;

-(void)event:(NSString *)eventId inviteFriends:(NSArray *)freindIdArray completion:(void (^)())completionBlock;
-(void)event:(NSString *)eventId changeRsvpStatusTo:(NSString *)status completion:(void (^)())completionBlock;

@end
