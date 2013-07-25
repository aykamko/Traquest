//
//  EventsTableViewDataSource.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventsTableViewDataSource.h"
@interface EventsTableViewDataSource()
@property (nonatomic,strong) NSArray *eventsList;

@end

@implementation EventsTableViewDataSource

- (id)initWithEventsList:(NSArray *)eventsList
{
    _eventsList=eventsList;
    return self;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"EventCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EventCell"];
    }
    
    NSString *cellLabel=_eventsList[indexPath.row][@"name"];
    NSLog(@"%@", _eventsList[indexPath.row][@"name"]);
    cell.textLabel.text=cellLabel;
    return cell;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    NSLog(@"lalalala");
    //NSLog(@"%d",_eventsList.count);
    return _eventsList.count;
}

@end
