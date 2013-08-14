//
//  FBEventDetailsViewController.h
//  EventsPlanner
//
//  Created by Ashwin Murthy on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

@interface FBEventDetailsViewController : UIViewController <UIScrollViewDelegate,UIActionSheetDelegate>

@property (nonatomic, strong) NSMutableDictionary *activeEventsDictionary;
-(NSMutableDictionary *)getActiveDict;
-(void)setIsActive: (BOOL)isActive;
- (id)initWithPartialDetails:(NSDictionary *)partialDetails isHost:(BOOL)isHost isActive:(BOOL)isActive;

@end
