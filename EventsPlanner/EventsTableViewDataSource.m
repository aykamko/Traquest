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
    
    return 0;

   

}

@end
