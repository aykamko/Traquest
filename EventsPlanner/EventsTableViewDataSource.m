//
//  EventsTableViewDataSource.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventsTableViewDataSource.h"
#import "EventsCell.h"
@interface EventsTableViewDataSource()

@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *guestEvents;

@end

@implementation EventsTableViewDataSource

-(id)initWithHostEvents:(NSArray *)hostEvents guestEvents:(NSArray *)guestEvents
{
    self = [super init];
    if (self) {
        _hostEvents = hostEvents;
        _guestEvents = guestEvents;
       
    }

    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *EventCellIdentifier = @"EventCell";
    EventsCell *cell = (EventsCell *)[tableView dequeueReusableCellWithIdentifier:EventCellIdentifier];
    
    if (!cell) {
        
        NSArray *eventArray;
        if (indexPath.section == 0) {
            eventArray = _hostEvents;
        } else {
            eventArray = _guestEvents;
        }
        
        // Arguments to pass to cell
        NSString *cellTitle;
        NSString *cellRsvpStatus;
        NSDate *cellDate;
        UIImage *cellThumbnail;
        
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
        
        NSString *imageURLStr = eventArray[indexPath.row][@"picture"][@"data"][@"url"];
        NSURL *URL = [NSURL URLWithString:imageURLStr];
        NSData *imageData = [NSData dataWithContentsOfURL:URL];
        cellThumbnail = [UIImage imageWithData:imageData];
        
        // Allocating and initializing actual cell
        cell = [[EventsCell alloc] initWithTitle:cellTitle
                                      rsvpStatus:cellRsvpStatus
                                            date:cellDate
                                       thumbnail:cellThumbnail
                                resuseIdentifier:EventCellIdentifier];
    }
    
    return cell;
  
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 2;
    
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
        } default: {
            return 0;
        }
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    switch (section) {
        case 0: {
            return @"Hosted Events";
            break;
        } case 1: {
            return @"Invited Events";
            break;
        } default: {
            return @"";
        }
    }
    
}


@end
