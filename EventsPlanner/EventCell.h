//
//  EventTableViewCell.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventCell : UITableViewCell

- (instancetype) initWithTitle:(NSString *)title
                          date:(NSDate *)date
                    background:(UIImage *)background
               reuseIdentifier:(NSString *)identifier;

@end
