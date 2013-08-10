//
//  CreateEventViewController.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/10/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EventsListController;

@interface CreateEventController : NSObject <UITextFieldDelegate>

- (id)initWithListController:(EventsListController *)eventsListController;
- (UIViewController *)presentableViewController;

@end
