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

@end

@implementation EventsTableViewDataSource

- (id)initWithHostEvents:(NSArray *)hostEvents guestEvents:(NSArray *)guestEvents noReplyEvents:(NSArray *)noReplyEvents
{
    self = [super init];
    if (self) {
        _hostEvents = hostEvents;
        _guestEvents = guestEvents;
        _noReplyEvents = noReplyEvents;
    }
    return self;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *EventCellIdentifier = @"EventCell";
    EventCell *cell = (EventCell*)[tableView dequeueReusableCellWithIdentifier:EventCellIdentifier];
    
    NSArray *eventArray;
    if (indexPath.section == 0) {
        eventArray = _hostEvents;
    } else if (indexPath.section == 1) {
        eventArray = _guestEvents;
    } else if (indexPath.section == 2) {
        eventArray = _noReplyEvents;
    }
    
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    switch (section) {
        case 0: {
            return _hostEvents.count;
            break;
        } case 1: {
            return _guestEvents.count;
            break;
        } case 2: {
            return _noReplyEvents.count;
        } default: {
            return 0;
        }
    }
    
}

@end
