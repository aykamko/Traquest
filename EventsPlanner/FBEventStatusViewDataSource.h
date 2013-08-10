//
//  FBEventTableViewDataSource.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/5/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBEventStatusViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong) NSArray *rsvpStatusOptions;

@end
