//
//  CreateEventPrivacyViewController.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/10/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CreateEventModel;

extern NSString * const kPublicPrivacyString;
extern NSString * const kFriendsOfGuestPrivacyString;
extern NSString * const kInviteOnlyPrivacyString;

@interface CreateEventPrivacyViewController : UITableViewController

@property (strong, nonatomic, readonly) NSString *privacyType;

- (id)initWithEventModel:(CreateEventModel *)createEventModel;

@end
