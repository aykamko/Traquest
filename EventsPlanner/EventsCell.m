//
//  EventsCell.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#define kSmallLabelFontSize           19.0f
#define kBigLabelFontSize             20.0f
#define kLabelSpacer                  0.5f
#define kMargins                      9.0f

#import "EventsCell.h"

@implementation EventsCell

- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
                   rsvpStatus:(NSString *)status
                         date:(NSDate *)date
                   background:(UIImage *)background
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        // Initializing labels
        _eventTitleLabel = [[UILabel alloc] init];
        _eventStatusLabel = [[UILabel alloc] init];
        _eventDateLabel = [[UILabel alloc] init];
        
        // Setting label text
        [_eventTitleLabel setText:title];
        [_eventStatusLabel setText:status];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDoesRelativeDateFormatting:YES];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_eventDateLabel setText:[dateFormatter stringFromDate:date]];
        
        
        // Event Title Label properties
        [_eventTitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *titleTopConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                              attribute:NSLayoutAttributeTop
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:_eventTitleLabel
                                                                              attribute:NSLayoutAttributeTop
                                                                             multiplier:1.0
                                                                               constant:-kMargins];
        NSLayoutConstraint *titleLeftConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                               attribute:NSLayoutAttributeLeft
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:_eventTitleLabel
                                                                               attribute:NSLayoutAttributeLeading
                                                                              multiplier:1.0
                                                                                constant:-kMargins];
        [_eventTitleLabel setFont:[UIFont boldSystemFontOfSize:kBigLabelFontSize]];
        [_eventTitleLabel setBackgroundColor:[UIColor clearColor]];
        [_eventTitleLabel setTextColor:[UIColor whiteColor]];
        
        // Event Status Label properties
        [_eventStatusLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *statusBottomConstraint = [NSLayoutConstraint constraintWithItem:_eventDateLabel
                                                                                  attribute:NSLayoutAttributeTop
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:_eventStatusLabel
                                                                                  attribute:NSLayoutAttributeBottom
                                                                                 multiplier:1.0
                                                                                   constant:0.0];
        NSLayoutConstraint *statusLeftConstraint = [NSLayoutConstraint constraintWithItem:_eventTitleLabel
                                                                                attribute:NSLayoutAttributeLeft
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:_eventStatusLabel
                                                                                attribute:NSLayoutAttributeLeft
                                                                               multiplier:1.0
                                                                                 constant:0];
        [_eventStatusLabel setFont:[UIFont systemFontOfSize:kSmallLabelFontSize]];
        [_eventStatusLabel setBackgroundColor:[UIColor clearColor]];
        [_eventStatusLabel setTextColor:[UIColor whiteColor]];
        
        
        // Event Date Label properties
        [_eventDateLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *dateBottomConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:_eventDateLabel
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                multiplier:1.0
                                                                                  constant:kMargins];
        NSLayoutConstraint *dateLeftConstraint = [NSLayoutConstraint constraintWithItem:_eventTitleLabel
                                                                               attribute:NSLayoutAttributeLeading
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:_eventDateLabel
                                                                               attribute:NSLayoutAttributeLeading
                                                                              multiplier:1.0
                                                                                constant:0.0];
        [_eventDateLabel setFont:[UIFont systemFontOfSize:kSmallLabelFontSize]];
        [_eventDateLabel setBackgroundColor:[UIColor clearColor]];
        [_eventDateLabel setTextColor:[UIColor whiteColor]];
        
        // Adding to superview
        [self addSubview:_eventTitleLabel];
        [self addSubview:_eventStatusLabel];
        [self addSubview:_eventDateLabel];
        
        // Adding constraints
        [self addConstraints:@[statusBottomConstraint, statusLeftConstraint,
                               titleTopConstraint, titleLeftConstraint,
                               dateBottomConstraint, dateLeftConstraint]];
    }
    return self;
}

@end
