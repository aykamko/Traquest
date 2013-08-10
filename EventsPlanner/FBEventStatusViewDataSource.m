//
//  FBEventTableViewDataSource.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/5/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBEventStatusViewDataSource.h"

@implementation FBEventStatusViewDataSource

- (id)init
{
    self = [super init];
    if (self) {
        _rsvpStatusOptions = @[@"Going",
                               @"Maybe",
                               @"Not Going"];
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *rsvpStatusCellIdentifier = @"RsvpStatusCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:rsvpStatusCellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:rsvpStatusCellIdentifier];
    }
    
    [[cell textLabel] setText:_rsvpStatusOptions[indexPath.row]];
    return cell;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_rsvpStatusOptions count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

@end
