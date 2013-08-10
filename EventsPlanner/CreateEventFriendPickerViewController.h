//
//  CreateEventFriendPickerViewController.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/11/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
@class CreateEventModel;

@interface CreateEventFriendPickerViewController : FBFriendPickerViewController

- (id)initWithEventModel:(CreateEventModel *)createEventModel;

@end
