//
//  FBEventDetailsTableDelegate.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/8/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBEventDetailsTableDelegate.h"
#import "FBEventDetailsTableDataSource.h"

static float kDetailsTableTextMargin;
static const float kTableViewSideMargin = 12.0;

@implementation FBEventDetailsTableDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Semi-hardcoded, but couldn't find a better way in a reasonable amount of time :P
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 6.1) {
        kDetailsTableTextMargin = 15.0;
    } else {
        kDetailsTableTextMargin = 10.0;
    }
    
    CGFloat cellWidth = [UIScreen mainScreen].bounds.size.width -
        (2 * (kTableViewSideMargin + kDetailsTableTextMargin));
    CGSize maxSize = CGSizeMake(cellWidth, 1500);
    
    FBEventDetailsTableDataSource *dataSource = tableView.dataSource;
    NSString *detailKey = dataSource.orderedDetailsKeys[indexPath.row];
    NSString *fieldString = dataSource.detailsDict[detailKey];
    
    CGSize cellSize = [fieldString
                       sizeWithFont:[UIFont fontWithName:@"Helvetica" size:14]
                       constrainedToSize:maxSize
                       lineBreakMode:NSLineBreakByWordWrapping];
    
    return cellSize.height + (2 * kDetailsTableTextMargin);

}

@end
