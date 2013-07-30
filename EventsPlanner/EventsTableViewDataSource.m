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
        cell = [[EventsCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:EventCellIdentifier guestEvents:_guestEvents hostEvents:_hostEvents indexPath:indexPath];
       cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
        } case 1: {
            return _guestEvents.count;
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
        } case 1: {
            return @"Invited Events";
        } default: {
            return @"";
        }
    }
    
}


@end
