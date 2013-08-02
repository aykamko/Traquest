//
//  EventHeaderView.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 7/31/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventHeaderView.h"

@implementation EventHeaderView

- (id)init
{
    self = [super init];
    if (self) {
        [self setTextColor:[UIColor colorWithRed:74.0/255.0 green:102.0/255.0 blue:167.0/255.0 alpha:1.0]];
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    UIEdgeInsets insets = {20, 25, 10, 0};
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
