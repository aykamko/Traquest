//
//  FBEventTableViewController.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/5/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBEventStatusTableController : NSObject

- (id)initWithStatus:(NSString *)status completion:(void (^)(NSString *newStatus))completionBlock;
- (UIViewController *)presentableViewController;

@end
