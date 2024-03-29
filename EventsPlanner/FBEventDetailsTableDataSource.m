//
//  FBGuestEventsDetailsDataSource.m
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBEventDetailsTableDataSource.h"

@interface FBEventDetailsTableDataSource ()

@property (nonatomic, strong) NSMutableArray *mutableOrderedDetailsKeys;
@property (nonatomic, strong) NSMutableDictionary *mutableDetailsDict;

@end

@implementation FBEventDetailsTableDataSource

- (id)initWithEventDetails: (NSMutableDictionary *) eventDetails
{
    self = [super init];
    if (self) {
        _mutableOrderedDetailsKeys = [[NSMutableArray alloc] init];
        _mutableDetailsDict = [eventDetails mutableCopy];
        _mutableOrderedDetailsKeys = [@[@"location", @"privacy", @"start_time", @"description", @"owner"] mutableCopy];
        [self parseEventDetails:_mutableDetailsDict];
    }
    return self;
}



#pragma mark Details Methods


- (void) updateObject: (NSString *) value forKey: (NSString *) key {
    [_mutableDetailsDict setObject:value forKey:key];
}
- (NSArray *)orderedDetailsKeys
{
    return [NSArray arrayWithArray:self.mutableOrderedDetailsKeys];
}

- (NSDictionary *)detailsDict
{
    return [NSDictionary dictionaryWithDictionary:self.mutableDetailsDict];
}

- (void)parseEventDetails:(NSMutableDictionary *)details {
    
    details[@"location"] = details[@"location"]? details[@"location"]:@" ";
    
    details[@"privacy"] = [NSMutableString stringWithString:[details[@"privacy"] isEqualToString:@"OPEN"]? @"Public":@"Invite Only"];
    
    NSString *startTime = details[@"start_time"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSString *dateString = @"";
    NSDate *date;
    
    if ([startTime rangeOfString:@"T"].location==NSNotFound) {
        [formatter setDateFormat:@"yyyy-MM-dd"];
        date = [formatter dateFromString:startTime];
        [formatter setDateFormat:@"EEEE',' MMMM dd, yyyy"];
        dateString = [formatter stringFromDate:date];

    } else {
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        date = [formatter dateFromString:startTime];
        [formatter setDateFormat:@"EEEE',' MMMM dd',' 'at' h:mm a"];
        dateString = [formatter stringFromDate:date];
    }
    
    details[@"start_time"] = dateString;
    
    if (!details[@"description"]){
        [_mutableOrderedDetailsKeys removeObject:@"description"];
    }
    
    NSArray *array = details[@"admins"][@"data"];
    NSString *hostString  = @"";
    if(array) {
        if ([array count]>2) {
            NSString *firstAdmin = [array objectAtIndex:0][@"name"];
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

#pragma mark Table View Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_mutableOrderedDetailsKeys count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
    NSString *currentKey = _mutableOrderedDetailsKeys[[indexPath row]];
    NSString *currentText = _mutableDetailsDict[currentKey];
    [[cell textLabel] setText: currentText];
    
    return cell;
}



@end
