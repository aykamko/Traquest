//
//  EventTableViewCell.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventTableViewCell : UITableViewCell

- (instancetype) initWithTitle:(NSString *)title
                    rsvpStatus:(NSString *)status
                          date:(NSDate *)date
                    background:(UIImage *)background
               reuseIdentifier:(NSString *)identifier;


//used to reset information when reusing tablecells
-(void) setTitle:(NSString *)title
          rsvpStatus:(NSString *)status
                date:(NSDate *)date
          background:(UIImage *)background
     reuseIdentifier:(NSString *)identifier;

@end
