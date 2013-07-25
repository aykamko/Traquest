//
//  EventsListController.h
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EventsListController : NSObject<UITableViewDelegate>

-(id)initWithEventsList:(NSArray *)events;
- (id)presentableViewController;


@end
