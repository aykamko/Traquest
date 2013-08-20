//
//  CreateEventModel.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/12/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kNameEventParameterKey;
extern NSString * const kDescriptionEventParameterKey;
extern NSString * const kStartTimeEventParameterKey;
extern NSString * const kEndTimeEventParameterKey;
extern NSString * const kLocationEventParameterKey;
extern NSString * const kLocationIdEventParameterKey;
extern NSString * const kPrivacyTypeEventParameterKey;

// Not actually sent in first request
extern NSString * const kInvitedFriendIdsEventParameterKey;

@protocol CreateEventModelDelegate <NSObject>

- (void)didSetNameAndDescription;
- (void)reloadTableView;

@end

@interface CreateEventModel : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, strong) NSString *privacyType;

@property (nonatomic) BOOL isNewEvent;


@property (nonatomic, strong) NSArray *invitedFriendIds;

@property (nonatomic, strong) id<CreateEventModelDelegate> delegate;

- (NSDictionary *)validEvent;
- (id)initWithIsNew:(BOOL)isNewEvent;

@end
