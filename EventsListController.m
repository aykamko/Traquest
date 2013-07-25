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
@property (nonatomic, strong) NSArray *eventsList;

@end
@implementation EventsListController
-(id)initWithEventsList:(NSArray *)events {
    self=[super init];
    if(self){
        
        _eventsList=events;
     
        _tableViewDataSource = [[EventsTableViewDataSource alloc]initWithEventsList:events];
        
        _tableViewController=[[UITableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        [[_tableViewController tableView]setDelegate:self];
        [[_tableViewController tableView]setDataSource:_tableViewDataSource];
        [self setTableViewController:_tableViewController];
       // _tableViewController = tableViewController;
        
    }
    return self;
}

- (id)presentableViewController
{
    return [self tableViewController];
}


@end
