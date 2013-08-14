//
//  EventsTableViewDataSource.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventsTableViewDataSource.h"
#import "EventCell.h"
#import "NSDate+ExtraStuff.h"

@implementation EventsTableViewDataSource

- (id)initWithEventArray:(NSArray *)eventArray
{
    self = [super init];
    if (self) {
        _eventArray = eventArray;
        _activeEvents = [[NSMutableArray alloc] init];
        [self updateActiveEvents];
    }
    return self;
}

- (void) updateActiveEvents
{
    for (id obj in _eventArray)
    {
        NSString *startTimeString = obj[@"start_time"];
        
        
        NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormater setLocale:enUSPOSIXLocale];
        [dateFormater setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        
        NSDate *cellDate = [dateFormater dateFromString:startTimeString];
        
        if(!cellDate) {
            [dateFormater setDateFormat:@"YYYY-MM-dd"];
            cellDate = [dateFormater dateFromString:startTimeString];
            [dateFormater setDateFormat:@"EEEE',' MMMM dd, YYYY"];
            startTimeString = [dateFormater stringFromDate:cellDate];
        }
        else {
            [dateFormater setDateFormat:@"EEEE',' MMMM dd',' 'at' h:mm a"];
            startTimeString = [dateFormater stringFromDate:cellDate];
        }
        
        NSTimeInterval timeToStart = [cellDate timeIntervalSinceNow]/3600;
        
        if ((timeToStart > -1) && (timeToStart < 3)) {
                [_activeEvents addObject:obj];
        } else if (timeToStart > 3) {
            [_activeEvents removeObject:obj];
        }
            
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([_activeEvents count] == 0)
        return 1;
    else
        return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *EventCellIdentifier = @"EventCell";
    EventCell *cell = (EventCell*)[tableView dequeueReusableCellWithIdentifier:EventCellIdentifier];
    
    NSArray *eventArray = [[NSArray alloc] init];
    NSMutableArray *inactiveEventsArray = [[NSMutableArray alloc] init];
    
    for (id obj in _eventArray)
    {
        if (![_activeEvents containsObject:obj])
        {
            [inactiveEventsArray addObject:obj];
        }
    }
    _inactiveEvents = inactiveEventsArray;
    
    if ([_activeEvents count] > 0)
    {
        if ([indexPath section] == 0) {
            eventArray = _activeEvents;
        } else if ([indexPath section] == 1) {
            eventArray = inactiveEventsArray;
        }
    }
    else {
        eventArray = _eventArray;
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
    
    if(!cellDate) {
        [dateFormater setDateFormat:@"YYYY-MM-dd"];
        cellDate = [dateFormater dateFromString:startTimeStr];
        [dateFormater setDateFormat:@"EEEE',' MMMM dd, YYYY"];
        startTimeStr = [dateFormater stringFromDate:cellDate];
    }
    else {
        [dateFormater setDateFormat:@"EEEE',' MMMM dd',' 'at' h:mm a"];
        startTimeStr = [dateFormater stringFromDate:cellDate];
    }
    
    
    cellBackground = eventArray[indexPath.row][@"cover"];
    
    // Allocating and initializing actual cell
    cell = [[EventCell alloc] initWithTitle:cellTitle
                                 rsvpStatus:cellRsvpStatus
                                       date:cellDate
                                 background:cellBackground
                            reuseIdentifier:EventCellIdentifier];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_activeEvents.count > 0) {
        switch (section) {
            case 0:
                return @"Active Events";
            case 1:
                return @"Inactive Events";
            default: return @"oops";
        }
    } else {
        return @"Events";
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_activeEvents.count > 0) {
        switch (section) {
            case 0:
                return _activeEvents.count;
            case 1:
                return _eventArray.count - _activeEvents.count;
            default: return 0;
        }
    } else {
        return _eventArray.count;
    }
}



@end
