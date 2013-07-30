//
//  EventsCell.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#define kSmallLabelFontSize           13.0f
#define kBigLabelFontSize             15.0f
#define kLabelSpacer                  0.5f
#define kSpaceBetweenImageAndLabels   9.0f

#import "EventsCell.h"

@implementation EventsCell

- (instancetype)initWithTitle:(NSString *)title
                   rsvpStatus:(NSString *)status
                         date:(NSDate *)date
                    thumbnail:(UIImage *)thumbnail
             resuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        
        // Setting thumbnail
        [self.imageView setImage:thumbnail];
        
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
        NSLayoutConstraint *titleBottomConstraint = [NSLayoutConstraint constraintWithItem:_eventStatusLabel
                                                                                 attribute:NSLayoutAttributeTop
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:_eventTitleLabel
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                multiplier:1.0
                                                                                  constant:kSmallLabelFontSize - kBigLabelFontSize + 1.0 + kLabelSpacer];
        NSLayoutConstraint *titleLeftConstraint = [NSLayoutConstraint constraintWithItem:_eventStatusLabel
                                                                               attribute:NSLayoutAttributeLeading
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:_eventTitleLabel
                                                                               attribute:NSLayoutAttributeLeading
                                                                              multiplier:1.0
                                                                                constant:0.0];
        [_eventTitleLabel setFont:[UIFont boldSystemFontOfSize:kBigLabelFontSize]];
        [_eventTitleLabel setBackgroundColor:[UIColor clearColor]];
        
        // Event Status Label properties
        [_eventStatusLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *statusCenterConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                                  attribute:NSLayoutAttributeCenterY
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:_eventStatusLabel
                                                                                  attribute:NSLayoutAttributeCenterY
                                                                                 multiplier:1.0
                                                                                   constant:0.0];
        NSLayoutConstraint *statusLeftConstraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                                                attribute:NSLayoutAttributeRight
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:_eventStatusLabel
                                                                                attribute:NSLayoutAttributeLeft
                                                                               multiplier:1.0
                                                                                 constant:-kSpaceBetweenImageAndLabels];
        [_eventStatusLabel setFont:[UIFont systemFontOfSize:kSmallLabelFontSize]];
        [_eventStatusLabel setTextColor:[UIColor lightGrayColor]];
        [_eventStatusLabel setBackgroundColor:[UIColor clearColor]];
        
        
        // Event Date Label properties
        [_eventDateLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *dateTopConstraint = [NSLayoutConstraint constraintWithItem:_eventStatusLabel
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:_eventDateLabel
                                                                                 attribute:NSLayoutAttributeTop
                                                                                multiplier:1.0
                                                                                  constant:0.0 - kLabelSpacer];
        NSLayoutConstraint *dateLeftConstraint = [NSLayoutConstraint constraintWithItem:_eventStatusLabel
                                                                               attribute:NSLayoutAttributeLeading
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:_eventDateLabel
                                                                               attribute:NSLayoutAttributeLeading
                                                                              multiplier:1.0
                                                                                constant:0.0];
        [_eventDateLabel setFont:[UIFont systemFontOfSize:kSmallLabelFontSize]];
        [_eventDateLabel setTextColor:[UIColor lightGrayColor]];
        [_eventDateLabel setBackgroundColor:[UIColor clearColor]];
        
        
        // Adding to superview
        [self.contentView addSubview:_eventTitleLabel];
        [self.contentView addSubview:_eventStatusLabel];
        [self.contentView addSubview:_eventDateLabel];
        
        // Adding constraints
        [self.contentView addConstraints:@[statusCenterConstraint, statusLeftConstraint]];
        [self.contentView addConstraints:@[titleBottomConstraint, titleLeftConstraint]];
        [self.contentView addConstraints:@[dateTopConstraint, dateLeftConstraint]];
    }
    return self;
}

@end
