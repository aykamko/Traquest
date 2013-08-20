//
//  EventsListController.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventsTableViewDataSource.h"

@class FBEventDetailsViewController;

typedef enum eventType {
    hostedEvent=0,
    guestEvent=1,
    noReplyEvent=2
}eventType;

@interface EventsListController : NSObject<UITableViewDelegate>

@property (nonatomic, strong) EventsTableViewDataSource *tableActiveViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *hostTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *attendingTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *maybeTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *notRepliedTableViewDataSource;

+ (EventsListController *)sharedListController;

- (id)initWithActiveHostEvents:(NSArray *)activeHostEvents
             activeGuestEvents:(NSArray *)activeGuestEvents
                    hostEvents:(NSArray *)hostEvents
               attendingEvents:(NSArray *)attendingEvents
              notRepliedEvents:(NSArray *)noReplyEvents
                maybeAttending:(NSArray *)maybeAttending;

- (id)presentableViewController;

- (void)pushEventDetailsViewControllerWithPartialDetails:(NSDictionary *)partialDetails
                                                isActive: (BOOL) active
                                                  isHost:(BOOL)isHost
                                              hasReplied:(BOOL)replied;

- (void)refreshTableViewForEventsListKey:(NSString *)eventsListKey
                           newEventsList:(NSArray *)eventsList
             endRefreshForRefreshControl:(UIRefreshControl *)refreshControl;




@end
