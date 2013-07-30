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

@property (nonatomic, strong) UIImage *eventImage;
@property (nonatomic, strong) UILabel *eventTitleLabel;
@property (nonatomic, strong) UILabel *eventStatusLabel;
@property (nonatomic, strong) UILabel *eventDateLabel;

- (instancetype)initWithTitle:(NSString *)title
                   rsvpStatus:(NSString *)status
                         date:(NSDate *)date
                    thumbnail:(UIImage *)thumbnail
             resuseIdentifier:(NSString *)identifier;

@end
