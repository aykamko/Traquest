//
//  EventsListController.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum eventType {
    hostedEvent=0,
    guestEvent=1
}eventType;

@interface EventsListController : NSObject<UITableViewDelegate>

- (id)initWithHostEvents:(NSArray *)hostEvents guestEvents:(NSArray *)guestEvents;
- (id)presentableViewController;




@end
