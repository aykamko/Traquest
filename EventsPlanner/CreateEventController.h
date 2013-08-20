//
//  CreateEventViewController.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/10/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CreateEventModel.h"
#import "FBEventDetailsViewController.h"

@class EventsListController;

@interface CreateEventController : NSObject <UITextFieldDelegate>

@property (nonatomic, strong) CreateEventModel *createEventModel;
@property (nonatomic, strong) NSString *existingEventId;
@property (nonatomic) BOOL isNewEvent;

- (id)initWithListController:(EventsListController *)eventsListController;
- (id)initWithDetailViewController:(FBEventDetailsViewController *)detailViewController
    eventDetails: (NSDictionary *)eventDetails eventId:(NSString *)eventId isNewEvent:(BOOL)isNewEvent;

- (UIViewController *)presentableViewController;

@end
