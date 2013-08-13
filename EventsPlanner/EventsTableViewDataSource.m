//
//  EventsTableViewDataSource.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventsTableViewDataSource.h"
#import "EventCell.h"

@interface EventsTableViewDataSource()

@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *guestEvents;
@property (nonatomic, strong) NSArray *noReplyEvents;
@property (nonatomic, strong) NSArray *maybeAttending;

@property (nonatomic, strong) NSArray *eventArray;


@end

@implementation EventsTableViewDataSource

- (id)initWithHostEvents:(NSArray *)hostEvents guestEvents:(NSArray *)guestEvents noReplyEvents:(NSArray *)noReplyEvents
          maybeAttending:(NSArray *)maybeAttending
{
    self = [super init];
    if (self) {
        _hostEvents = hostEvents;
        _guestEvents = guestEvents;
        _noReplyEvents = noReplyEvents;
        _maybeAttending = maybeAttending;
    }
    return self;
}

- (id)initWithEvents:eventArray
{
    self = [super init];
    if (self) {
        _eventArray = eventArray;
    }
    return self;
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *EventCellIdentifier = @"EventCell";
    EventCell *cell = (EventCell*)[tableView dequeueReusableCellWithIdentifier:EventCellIdentifier];
    
    NSArray *eventArray;
    eventArray = _eventArray;
    
//    if (indexPath.section == 0) {
//        eventArray = _hostEvents;
//    } else if (indexPath.section == 1) {
//        eventArray = _guestEvents;
//    } else if (indexPath.section == 2) {
//        eventArray = _maybeAttending;
//    } else if (indexPath.section == 3) {
//        eventArray = _noReplyEvents;
//    }
    
    // Arguments to pass to cell
    NSString *cellTitle;
    NSString *cellRsvpStatus;
    NSDate *cellDate;
    UIImage *cellBackground;
    
    // Getting arguments
    cellTitle = eventArray[indexPath.row][@"name"];
    
    cellRsvpStatus = eventArray[indexPath.row][@"rsvp_status"];
    if ([cellRsvpStatus isEqualToString:@"attending"]) {
        cellRsvpStatus = @"You're going.";
    } else if ([cellRsvpStatus isEqualToString:@"unsure"]) {
        cellRsvpStatus = @"You maybe going.";
    } else if ([cellRsvpStatus isEqualToString:@"not_replied"]) {
        cellRsvpStatus = @"You haven't replied.";
    }
    
    NSString *startTimeStr = eventArray[indexPath.row][@"start_time"];
    
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormater setLocale:enUSPOSIXLocale];
    [dateFormater setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    cellDate = [dateFormater dateFromString:startTimeStr];
    
    cellBackground = eventArray[indexPath.row][@"cover"];
    
    // Allocating and initializing actual cell
    
    cell = [[EventCell alloc] initWithTitle:cellTitle
                                 rsvpStatus:cellRsvpStatus
                                       date:cellDate
                                 background:cellBackground
                            reuseIdentifier:EventCellIdentifier];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _eventArray.count;
}

@end
