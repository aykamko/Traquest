//
//  FBHostEventDetailsViewController.h
//  EventsPlanner
//
//  Created by Anupa Murali on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import "LoginViewController.h"
#import "ActiveEventMapViewController.h"
#import <GoogleMaps/GoogleMaps.h>

@interface FBHostEventDetailsViewController : UIViewController <CLLocationManagerDelegate>

@property (strong, nonatomic) NSMutableArray *friendsIDArray;
@property BOOL startTracking;
@property (strong, nonatomic) IBOutlet UILabel *addressLabel;
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

- (id)initWithHostEventDetails:(NSDictionary *)details;
- (id) initFriendsIDArray:(NSMutableArray *)attendingFriends;
-(IBAction)loadMapView:(id)sender;

@end
