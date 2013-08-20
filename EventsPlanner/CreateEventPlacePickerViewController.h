//
//  CreateEventPlacePickerViewController.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/12/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
@class CreateEventModel;

@interface CreateEventPlacePickerViewController : FBPlacePickerViewController



- (id)initWithEventModel:(CreateEventModel *)createEventModel;

@end
