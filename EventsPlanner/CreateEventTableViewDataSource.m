//
//  NewEventTableViewDataSource.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/9/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "CreateEventTableViewDataSource.h"
#import "CreateEventTimePickerViewController.h"
#import "CreateEventPrivacyViewController.h"
#import "GraphicsConstants.h"
#import "NSDate+ExtraStuff.h"

@interface CreateEventTableViewDataSource () <UITextFieldDelegate>

@property (strong, nonatomic) CreateEventModel *createEventModel;

@property (strong, nonatomic) UITextField *nameTextField;
@property (strong, nonatomic) UITextField *descriptionTextField;


@end

@implementation CreateEventTableViewDataSource

- (id)initWithEventModel:(CreateEventModel *)createEventModel
{
    self = [super init];
    if (self) {
       
        self.createEventModel = createEventModel;
        _timePickerViewController = [[CreateEventTimePickerViewController alloc]
                                     initWithEventModel:createEventModel];
        _privacyViewController = [[CreateEventPrivacyViewController alloc]
                                  initWithEventModel:createEventModel];
        
    }
    return self;
}
#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            return 3;
            break;
        case 2:
            return 1;
            break;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        
        UITextField *textField = [[UITextField alloc] init];
        [textField setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [textField setDelegate:self];
        
        NSDictionary *viewsDict = @{ @"textField":textField };
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:nil];
        
        if (indexPath.row == 0) {
            
            self.nameTextField = textField;
            textField.placeholder = @"Event name";
            
            if (self.createEventModel.name) {
                textField.text = self.createEventModel.name;
            }
            
        } else if (indexPath.row == 1) {
            
            self.descriptionTextField = textField;
            textField.placeholder = @"Details";
            
            if (self.createEventModel.description) {
                textField.text = self.createEventModel.description;
            }
            
        }
        
        [cell.contentView addSubview:textField];
        
        NSInteger textFieldMargin;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] > 6.1) {
            textFieldMargin = kTableCellMarginiOS7;
        } else {
            textFieldMargin = kTableCellMargin;
        }
        
        NSDictionary *metricsDict = @{ @"margin":[NSNumber numberWithInteger:textFieldMargin] };
        
        [cell.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|[textField]|"
                                          options:0
                                          metrics:metricsDict
                                          views:viewsDict]];
        [cell.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-(margin)-[textField]-(margin)-|"
                                          options:0
                                          metrics:metricsDict
                                          views:viewsDict]];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
        
    } else if (indexPath.section == 1) {
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                       reuseIdentifier:nil];
        [cell.textLabel setFont:[UIFont boldSystemFontOfSize:kDefaultTableCellFontSize]];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
        NSInteger row = indexPath.row;
        if (row == 0) {
            
            cell.textLabel.text = @"Location";
            
            if (self.createEventModel.location) {
                cell.detailTextLabel.text = self.createEventModel.location;
            } else {
                cell.detailTextLabel.text = @"Add Place";
            }
            
        } else if (row == 1) {
            
            cell.textLabel.text = @"Date & Time";
            
            NSDate *timePickerDate = self.createEventModel.startTime;
            NSString *dateString = [NSDate prettyReadableStringFromDate:timePickerDate];
            cell.detailTextLabel.text = dateString;
            
        } else if (row == 2) {
            
            cell.textLabel.text = @"People Invited";
            
            if (self.createEventModel.invitedFriendIds) {
                NSInteger numberOfInvites = self.createEventModel.invitedFriendIds.count;
                
                NSString *friendCountString = @"%d Friends";
                if (numberOfInvites == 1) {
                    friendCountString = @"%d Friend";
                }
                
                cell.detailTextLabel.text = [NSString stringWithFormat:friendCountString, numberOfInvites];
                
            } else {
                cell.detailTextLabel.text = @"Invite Friends";
            }
            
        }
        
        return cell;
        
    } else if (indexPath.section == 2) {
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                       reuseIdentifier:nil];
        [cell.textLabel setFont:[UIFont boldSystemFontOfSize:kDefaultTableCellFontSize]];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
        cell.textLabel.text = @"Privacy";
        cell.detailTextLabel.text = self.privacyViewController.privacyType;
        
        return cell;
        
    } else {
        return nil;
    }
}

#pragma mark Textfield Methods

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if ([textField isEqual:self.nameTextField]) {
        
        self.createEventModel.name = textField.text;
        
    } else if ([textField isEqual:self.descriptionTextField]) {
        
        self.createEventModel.description = textField.text;
        
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
