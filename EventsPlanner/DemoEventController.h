//
//  DemoEventController.h
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/21/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import "ParseDataStore.h"
#import "ActiveEventController.h"

@interface DemoEventController : NSObject

@property (nonatomic, strong) ActiveEventController *activeDemoController;

- (UIViewController *)presentableViewController;

@end
