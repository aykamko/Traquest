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

- (id)initWithPartialDetails:(NSDictionary *)partialDetails isActive:(BOOL)active isHost:(BOOL)isHost hasReplied:(BOOL)hasReplied;
- (void)refreshDetailsViewWithCompleteDetails:(NSDictionary *)completeEventDetails;

@end
