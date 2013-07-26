//
//  EventsTableViewDataSource.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventsTableViewDataSource.h"
@interface EventsTableViewDataSource()
@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *guestEvents;

@end

@implementation EventsTableViewDataSource

-(id)initWithHostEvent:hostEvents guestEvents:guestEvents
{
    self = [super init];
    if (self) {
        _hostEvents = hostEvents;
        _guestEvents = guestEvents;
    }

    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

//    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"EventCell"];
//    
//    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EventCell"];
//    }
//    
//    NSString *cellLabel=_eventsList[indexPath.row][@"name"];
//    cell.textLabel.text=cellLabel;
//    return cell;
    return 0;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    _guestOf=[[NSMutableArray alloc]init];
    [ _guestOf addObject:@"1"];
    
    _hostOf=[[NSMutableArray alloc]init];
    [_hostOf addObject:@"2"];
    [_hostOf addObject:@"3"];
    
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"EventCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EventCell"];
    }
    
    if (indexPath.section == 0) {
        [[cell textLabel] setText:(NSString *)[_hostOf objectAtIndex:indexPath.row]];
    } else if (indexPath.section == 1) {
        [[cell textLabel] setText:(NSString *)[_guestOf objectAtIndex:indexPath.row]];
    }

    return cell;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//    _num=_num++;
    if(section == 0 ){
    
        return 2;
    }
    
    else {
        return 1;
    }
}

}

@end
