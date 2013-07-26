//
//  EventsListController.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventsListController.h"
#import "EventsTableViewDataSource.h"
@interface EventsListController()
@property (nonatomic, strong) UITableViewController *tableViewController;
@property (nonatomic, strong) EventsTableViewDataSource *tableViewDataSource;

@end
@implementation EventsListController



- (id)initWithHostEvent:(NSArray *)hostEvents guestEvent:(NSArray *)guestEvents
{
    self = [super init];
    if (self) {
     
        _tableViewDataSource = [[EventsTableViewDataSource alloc] initWithHostEvent:hostEvents guestEvent:guestEvents];
        
        _tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [[_tableViewController tableView] setDelegate:self];
        [[_tableViewController tableView] setDataSource:_tableViewDataSource];
        [self setTableViewController:_tableViewController];
        
    }
    return self;
}

- (id)presentableViewController
{
    return [self tableViewController];
}


@end
