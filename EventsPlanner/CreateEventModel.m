//
//  CreateEventModel.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/12/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "CreateEventModel.h"
#import "CreateEventPrivacyViewController.h"
#import "NSDate+ExtraStuff.h"

NSString * const kNameEventParameterKey = @"name";
NSString * const kStartTimeEventParameterKey = @"start_time";
NSString * const kEndTimeEventParameterKey = @"end_time";
NSString * const kDescriptionEventParameterKey = @"description";
NSString * const kLocationEventParameterKey = @"location";
NSString * const kLocationIdEventParameterKey = @"location_id";
NSString * const kPrivacyTypeEventParameterKey = @"privacy_type";

NSString * const kInvitedFriendIdsEventParameterKey = @"invited_friends";

@interface CreateEventModel ()

@property (nonatomic, getter = isValidEvent) BOOL validEvent;

@end

@implementation CreateEventModel

- (CreateEventModel *)copyOfModel
{
    CreateEventModel *newModel = [[CreateEventModel alloc] init];
    newModel.name = [self.name copy];
    newModel.startTime = [self.startTime copy];
    newModel.endTime = [self.endTime copy];
    newModel.description = [self.description copy];
    newModel.location = [self.location copy];
    newModel.locationId = [self.locationId copy];
    newModel.privacyType = [self.privacyType copy];
    
    return newModel;
}

- (void)setName:(NSString *)name
{
    _name = name;
    
    if ([self.name isEqualToString:@""]) {
        _name = nil;
    }
    
    [self checkEventValidity];
}

- (void)setDescription:(NSString *)description
{
    _description = description;
    
    if ([self.description isEqualToString:@""]) {
        _description = nil;
    }
    
    [self checkEventValidity];
}

- (void)checkEventValidity
{
    if (self.name && self.description) {
        self.validEvent = YES;
        [self.delegate didSetNameAndDescription];
    } else {
        [self.delegate eventIsAtInvalidState];
    }
}

- (void)setStartTime:(NSDate *)startTime
{
    _startTime = startTime;
    [self.delegate reloadTableView];
}

- (void)setLocation:(NSString *)location
{
    _location = location;
    [self.delegate reloadTableView];
}

- (void)setPrivacyType:(NSString *)privacyType
{
    _privacyType = privacyType;
    [self.delegate reloadTableView];
}

- (void)setInvitedFriendIds:(NSArray *)invitedFriendIds
{
    _invitedFriendIds = invitedFriendIds;
    
    if ([self.invitedFriendIds count] == 0) {
        _invitedFriendIds = nil;
    }
    
    [self.delegate reloadTableView];
}

#pragma mark Return Methods
- (NSDictionary *)validEvent
{
    if (!self.isValidEvent) {
        return nil;
    }
    
    NSMutableDictionary *resultDict = [[NSMutableDictionary alloc]
                                       initWithDictionary: @{ kNameEventParameterKey: self.name,
                                                              kDescriptionEventParameterKey: self.description}];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    if (self.startTime) {
        NSString *startTimeISO8601String = [dateFormatter stringFromDate:self.startTime];
        if (startTimeISO8601String)
        {
            [resultDict addEntriesFromDictionary:@{ kStartTimeEventParameterKey: startTimeISO8601String }];
        }
    }
    
    if (self.endTime) {
        NSString *endTimeISO8601String = [dateFormatter stringFromDate:self.startTime];
        if (endTimeISO8601String)
        {
            [resultDict addEntriesFromDictionary:@{ kEndTimeEventParameterKey: endTimeISO8601String }];
        }
    }
    
    if (self.location) {
        [resultDict addEntriesFromDictionary:@{ kLocationEventParameterKey: self.location }];
    }
    
    if (self.locationId) {
        [resultDict addEntriesFromDictionary:@{ kLocationIdEventParameterKey: self.locationId }];
    }
    
    if (self.privacyType) {
        
        if ([self.privacyType isEqualToString:kPublicPrivacyString]) {
            
            self.privacyType = @"OPEN";
            
        } else if ([self.privacyType isEqualToString:kFriendsOfGuestPrivacyString]) {
            
            self.privacyType = @"FRIENDS";
            
        } else if ([self.privacyType isEqualToString:kInviteOnlyPrivacyString]) {
            
            self.privacyType = @"SECRET";
            
        }
        
        [resultDict addEntriesFromDictionary:@{ kPrivacyTypeEventParameterKey: self.privacyType }];
    }
    
    return resultDict;
}

- (NSDictionary *)onlyParametersChangedFromStoredModel:(CreateEventModel *)storedModel
{
    if (!storedModel) {
        return nil;
    }
    
    NSMutableDictionary *differenceDict = [[NSMutableDictionary alloc] init];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    if (![self.name isEqualToString:storedModel.name]) {
        [differenceDict addEntriesFromDictionary:@{ kNameEventParameterKey: self.name }];
    }
    
    if (![self.description isEqualToString:storedModel.description]) {
        [differenceDict addEntriesFromDictionary:@{ kDescriptionEventParameterKey: self.description }];
    }
    
    if (self.startTime && ![self.startTime isEqualToDate:storedModel.startTime]) {
        NSString *startTimeISO8601String = [dateFormatter stringFromDate:self.startTime];
        if (startTimeISO8601String)
        {
            [differenceDict addEntriesFromDictionary:@{ kStartTimeEventParameterKey: startTimeISO8601String }];
        }
    }
    
    if (self.endTime && ![self.endTime isEqualToDate:storedModel.endTime]) {
        NSString *endTimeISO8601String = [dateFormatter stringFromDate:self.endTime];
        if (endTimeISO8601String)
        {
            [differenceDict addEntriesFromDictionary:@{ kEndTimeEventParameterKey: endTimeISO8601String }];
        }
    }
    
    if (self.location && ![self.location isEqualToString:storedModel.location]) {
        [differenceDict addEntriesFromDictionary:@{ kLocationEventParameterKey: self.location }];
    }
    
    if (self.locationId && ![self.locationId isEqualToString:storedModel.locationId]) {
        [differenceDict addEntriesFromDictionary:@{ kLocationIdEventParameterKey: self.locationId }];
    }
    
    if (self.privacyType && ![self.privacyType isEqualToString:storedModel.privacyType]) {
        
        if ([self.privacyType isEqualToString:kPublicPrivacyString]) {
            
            self.privacyType = @"OPEN";
            
        } else if ([self.privacyType isEqualToString:kFriendsOfGuestPrivacyString]) {
            
            self.privacyType = @"FRIENDS";
            
        } else if ([self.privacyType isEqualToString:kInviteOnlyPrivacyString]) {
            
            self.privacyType = @"SECRET";
            
        }
        
        [differenceDict addEntriesFromDictionary:@{ kPrivacyTypeEventParameterKey: self.privacyType }];
    }
    
    if ([differenceDict allKeys] > 0) {
        return differenceDict;
    } else {
        return nil;
    }
    
}

@end
