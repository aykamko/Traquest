//
//  EventsListController.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum eventType {
    hostedEvent=0,
    guestEvent=1,
    noReplyEvent=2
}eventType;

@interface EventsListController : NSObject<UITableViewDelegate>

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

@property (nonatomic, strong) NSMutableDictionary *trackingDict;
@end
