//
//  CreateEventTimePickerViewController.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/10/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CreateEventModel;

@interface CreateEventTimePickerViewController : UIViewController

- (id)initWithEventModel:(CreateEventModel *)createEventModel;

@end