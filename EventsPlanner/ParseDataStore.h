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
-(id) initWithTrackingAndLocation;
- (void)logInWithCompletion:(void (^)())completionBlock;
-(void)logOutWithCompletion: (void (^)())completionBlock;
-(void)fetchLocationDataWithCompletion:(void (^)(NSArray *userLocations)) completionBlock;
- (void)fetchEventListDataWithCompletion:(void (^)(NSArray *hostEvents, NSArray *guestEvents, NSArray *friends))completionBlock;
+ (ParseDataStore *)sharedStore;
-(void)fetchFriendsWithCompletion:(void (^)(NSArray *friends)) completionBlock;
-(void)notifyUsersWithCompletion:(void(^)(NSArray *userLocations)) completionBlock;

@end
