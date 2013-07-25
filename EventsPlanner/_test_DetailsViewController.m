//
//  _test_DetailsViewController.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "_test_DetailsViewController.h"

@implementation _test_DetailsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [[self textView] setText:[self text]];
}

@end
