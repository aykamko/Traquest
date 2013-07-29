//
//  EventsCell.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>


@interface EventsCell : UITableViewCell
@property (nonatomic,strong) UIImage *eventImage;
@property (nonatomic,strong) UILabel *eventTitle;
@property (nonatomic,strong) UILabel *eventDate;
-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier guestEvents:(NSArray *)guestEvents hostEvents:(NSArray *)hostEvents indexPath:(NSIndexPath *)indexPath;

@end
