//
//  EventsCell.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>


@interface EventsCell : UIView

@property (nonatomic, strong) UIImage *eventImage;
@property (nonatomic, strong) UILabel *eventTitleLabel;
@property (nonatomic, strong) UILabel *eventStatusLabel;
@property (nonatomic, strong) UILabel *eventDateLabel;

- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
                   rsvpStatus:(NSString *)status
                         date:(NSDate *)date
                   background:(UIImage *)background;

@end
