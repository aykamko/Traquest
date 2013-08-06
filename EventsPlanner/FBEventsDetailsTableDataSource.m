//
//  FBGuestEventsDetailsDataSource.m
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBEventsDetailsTableDataSource.h"

@interface FBEventsDetailsTableDataSource () {
    NSMutableArray *_relevantDetailsKeys;
    NSMutableDictionary *_allDetails;
}

@end

@implementation FBEventsDetailsTableDataSource

- (id)initWithEventDetails: (NSMutableDictionary *) eventDetails
{
    self = [super init];
    if (self) {
        _relevantDetailsKeys = [[NSMutableArray alloc] init];
        _allDetails = [eventDetails mutableCopy];
        _relevantDetailsKeys = [(NSArray*)@[@"location", @"privacy", @"start_time", @"description", @"owner"] mutableCopy];
        [self parseEventDetails:_allDetails];
    }
    return self;
}

-(void) parseEventDetails: (NSMutableDictionary *) details {
    
    details[@"location"] = details[@"location"]? details[@"location"]:@" ";
    
    details[@"privacy"] = [NSMutableString stringWithString:[details[@"privacy"] isEqualToString:@"OPEN"]? @"Public":@"Invite Only"];
    
    NSString *startTime = details[@"start_time"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ssZ"];
    NSDate *date =[formatter dateFromString:startTime];
    NSString *dateString = @"";
    if(!date) {
        [formatter setDateFormat:@"YYYY-MM-dd"];
        date = [formatter dateFromString:startTime];
        [formatter setDateFormat:@"EEEE',' MMMM dd, YYYY"];
        dateString = [formatter stringFromDate:date];
    }
    else {
        [formatter setDateFormat:@"EEEE',' MMMM dd',' 'at' h:mm a"];
        dateString = [formatter stringFromDate:date];
    }
    
    details[@"start_time"] = dateString;
    
    if (!details[@"description"]){
        [_relevantDetailsKeys removeObject:@"description"];
    }
    
    NSArray *array = details[@"admins"][@"data"];
    NSString *hostString  = @"";
    if(array) {
        if ([array count]>2) {
            NSString *firstAdmin = [array firstObject][@"name"];
            hostString = [NSString stringWithFormat:@"Hosted by %@ and %d others",firstAdmin,[array count]-1];
        } else {
            NSMutableString *namesString = [[NSMutableString alloc] init];
            [namesString appendString:array[0][@"name"]];
            if([array count]==2) {
                [namesString appendString:[NSString stringWithFormat:@" and %@ ",array[1][@"name"]]];
            }
            hostString =[NSString stringWithFormat:@"Hosted by %@",namesString];
        }
    } else {
        if (details[@"owner"]) {
            NSString * ownerString = details[@"owner"][@"name"];
            hostString =[NSString stringWithFormat:@"Hosted by %@",ownerString];
        }
    }
    details[@"owner"] = hostString;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_relevantDetailsKeys count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setUserInteractionEnabled:NO];
    [cell textLabel].lineBreakMode = NSLineBreakByWordWrapping;
    [cell textLabel].numberOfLines = 0;
    [[cell textLabel] setTextColor:[UIColor colorWithWhite:0 alpha:0.4]];
    [[cell textLabel] setFont:[UIFont fontWithName:@"Helvetica" size:14]];
    NSString *currentKey = _relevantDetailsKeys[[indexPath row]];
    [[cell textLabel] setText: _allDetails[currentKey]];
    return cell;
}

-(void) updateObject: (NSString *) value forKey: (NSString *) key {
    [_allDetails setObject:value forKey:key];
}

@end
