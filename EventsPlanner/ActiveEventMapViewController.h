//
//  ActiveEventMapViewController.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ActiveEventMapViewController : UIViewController


@property (strong, nonatomic) NSMutableDictionary *friendsIDDictionary;


- (id) initWithGuests:(NSMutableSet *)attendingFriends userLocations: (NSDictionary *) userLocations venueLocation:(CLLocationCoordinate2D) venueLocation userInfo: (NSMutableDictionary *)userInfo;
@end
