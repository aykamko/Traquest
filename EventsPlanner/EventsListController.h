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
    guestEvent=1,
    noReplyEvent=2
}eventType;

@interface EventsListController : NSObject<UITableViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *logoutButton;

- (id)initWithHostEvents:hostEvents guestEvents:guestEvents noReplyEvents:noReplyEvents maybeAttending:maybeAttending;
- (id)presentableViewController;
-(IBAction)logUserOut:(id)sender;

@end
