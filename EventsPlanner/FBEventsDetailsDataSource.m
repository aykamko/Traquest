//
//  FBGuestEventsDetailsDataSource.m
//  EventsPlanner
//
//  Created by Ashwin Murthy on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBEventsDetailsDataSource.h"

@interface FBEventsDetailsDataSource () {
    NSMutableArray *_relevantDetails;
    NSMutableDictionary *_allDetails;
}

@end

@implementation FBEventsDetailsDataSource

- (id)initWithEventDetails: (NSMutableDictionary *) eventDetails
{
    self = [super init];
    if (self) {
        _relevantDetails = [[NSMutableArray alloc] init];
        _allDetails = eventDetails;
        [self parseEventDetails:eventDetails];
    }
    return self;
}

-(void) parseEventDetails: (NSMutableDictionary *) details {
    
    [_relevantDetails addObject:details[@"location"]];
    
    NSMutableString *privacyString= [NSMutableString stringWithString:[details[@"privacy"] isEqualToString:@"OPEN"]? @"Public":@"Invite Only"];
    
    NSString *startTime = details[@"start_time"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ssZ"];
    NSDate *date =[formatter dateFromString:startTime];
    [formatter setDateFormat:@"EEEE',' MMMM dd',' 'at' h:mm a"];
    NSString *dateString = [formatter stringFromDate:date];
    
    [_relevantDetails addObject:[NSString stringWithFormat:@"%@\n%@",privacyString,dateString ]];
    
    if (details[@"description"])
        [_relevantDetails addObject:details[@"description"]];
    
    NSArray *array = details[@"admins"][@"data"];
    if(array) {
        if ([array count]>2) {
            NSString *firstAdmin = [array firstObject][@"name"];
            [_relevantDetails addObject:[NSString stringWithFormat:@"Hosted by %@ and %d others",firstAdmin,[array count]-1]];
        } else {
            NSMutableString *namesString = [[NSMutableString alloc] init];
            [namesString appendString:array[0][@"name"]];
            if([array count]==2) {
                [namesString appendString:[NSString stringWithFormat:@" and %@ ",array[1][@"name"]]];
            }
            [_relevantDetails addObject:[NSString stringWithFormat:@"Hosted by %@",namesString]];
        }
    } else {
        if (details[@"owner"]) {
            NSString * ownerString = details[@"owner"][@"name"];
            [_relevantDetails addObject:[NSString stringWithFormat:@"Hosted by %@",ownerString]];
        }
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_relevantDetails count];
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
    NSLog(@"%f",cell.frame.size.height);
    [[cell textLabel] setTextColor:[UIColor colorWithWhite:0 alpha:0.4]];
    [[cell textLabel] setFont:[UIFont fontWithName:@"Helvetica" size:14]];
    NSLog(@"%@",[[cell textLabel] font ]);
    [[cell textLabel] setText:_relevantDetails[[indexPath row]] ];
    return cell;
}

@end
