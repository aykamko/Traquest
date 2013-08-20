//
//  CreateEventViewController.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/10/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "CreateEventController.h"
#import "CreateEventTableViewDataSource.h"
#import "CreateEventFriendPickerViewController.h"
#import "CreateEventTimePickerViewController.h"
#import "CreateEventPlacePickerViewController.h"
#import "CreateEventPrivacyViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "ParseDataStore.h"
#import "GraphicsConstants.h"

#import "EventsListController.h"

@interface CreateEventController () <UITableViewDelegate, CreateEventModelDelegate>

@property (nonatomic, strong) CreateEventModel *createEventModel;
@property (nonatomic, strong) CreateEventModel *storedEventModel;

@property (nonatomic, strong) NSString *existingEventId;

@property (nonatomic, strong) EventsListController *eventsListController;
@property (nonatomic, strong) FBEventDetailsViewController *detailViewController;


@property (nonatomic, strong) UITableViewController *tableViewController;
@property (nonatomic, strong) CreateEventTableViewDataSource *dataSource;

@property (nonatomic, strong) CreateEventFriendPickerViewController *friendPickerViewController;
@property (nonatomic, strong) CreateEventPlacePickerViewController *placePickerViewController;

@property (nonatomic, strong) CreateEventPrivacyViewController *privacyViewController;

- (void)cancel:(id)sender;
- (void)createEvent:(id)sender;

@end

@implementation CreateEventController

- (id)initWithListController:(EventsListController *)eventsListController;
{
    self = [super init];
    if (self) {
        
        self.eventsListController = eventsListController;
        
        self.createEventModel = [[CreateEventModel alloc] init];
        self.createEventModel.delegate = self;
        
        self.dataSource = [[CreateEventTableViewDataSource alloc] initWithEventModel:self.createEventModel
                                                                       existingEvent:NO];
        
        self.tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.tableViewController.tableView setScrollEnabled:NO];
        [self.tableViewController setTitle:@"Create Event"];
        [self.tableViewController.tableView setDataSource:self.dataSource];
        [self.tableViewController.tableView setDelegate:self];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(cancel:)];
        self.tableViewController.navigationItem.leftBarButtonItem = cancelButton;
        

        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(createEvent:)];
        self.tableViewController.navigationItem.rightBarButtonItem = doneButton;
        self.tableViewController.navigationItem.rightBarButtonItem.enabled = NO;
        
        self.tableViewController.navigationItem.hidesBackButton = YES;
        self.tableViewController.navigationController.navigationBar.translucent = NO;

        
    }
    return self;
}

- (id)initWithDetailViewController:(FBEventDetailsViewController *)detailViewController
                      eventDetails:(NSDictionary *)eventDetails
{
    self = [super init];
    if (self) {
        
        self.detailViewController = detailViewController;
        _existingEventId = eventDetails[@"id"];
        
        self.createEventModel = [[CreateEventModel alloc] init];
        self.createEventModel.delegate = self;
        
        // Setting existing fields of event
        self.createEventModel.name = eventDetails[kNameEventParameterKey];
        self.createEventModel.description = eventDetails[kDescriptionEventParameterKey];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        
        if (eventDetails[kStartTimeEventParameterKey]) {
            self.createEventModel.startTime = [dateFormatter dateFromString:eventDetails[kStartTimeEventParameterKey]];
        }
        
        if (eventDetails[kEndTimeEventParameterKey]) {
            self.createEventModel.endTime = [dateFormatter dateFromString:eventDetails[kEndTimeEventParameterKey]];
        }
        
        self.createEventModel.location = eventDetails[kLocationEventParameterKey];
        self.createEventModel.locationId = eventDetails[@"venue"][@"id"];
        self.createEventModel.privacyType = eventDetails[@"privacy"];
        
        // For checking differences at the end
        self.storedEventModel = [self.createEventModel copyOfModel];
        
        self.dataSource = [[CreateEventTableViewDataSource alloc] initWithEventModel:self.createEventModel
                                                                       existingEvent:YES];
        
        self.tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.tableViewController.tableView setScrollEnabled:NO];
        [self.tableViewController setTitle:@"Edit Event"];
        [self.tableViewController.tableView setDataSource:self.dataSource];
        [self.tableViewController.tableView setDelegate:self];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(cancel:)];
        self.tableViewController.navigationItem.leftBarButtonItem = cancelButton;
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(createEvent:)];
        self.tableViewController.navigationItem.rightBarButtonItem = doneButton;
        
        self.tableViewController.navigationItem.hidesBackButton = YES;
        self.tableViewController.navigationController.navigationBar.translucent = NO;
        
    }
    return self;
}


#pragma mark Extra Methods

- (void)didSetNameAndDescription
{
    self.tableViewController.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)reloadTableView
{
    [self.tableViewController.tableView reloadData];
}

- (void)eventIsAtInvalidState
{
    if (self.tableViewController.navigationItem.rightBarButtonItem.enabled == YES) {
        self.tableViewController.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (UIViewController *)presentableViewController
{
    return self.tableViewController;
}

#pragma mark Table View Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        
        NSInteger row = indexPath.row;
        if (row == 0) {
            
            if (!self.placePickerViewController) {
                self.placePickerViewController = [[CreateEventPlacePickerViewController alloc]
                                                  initWithEventModel:self.createEventModel];
            }
            
            [self.tableViewController.navigationController pushViewController:self.placePickerViewController
                                                                     animated:YES];
            
        } else if (row == 1) {
            
            [self.tableViewController.navigationController pushViewController:self.dataSource.timePickerViewController
                                                                     animated:YES];
            
        } else if (row == 2) {
            
            if (!self.friendPickerViewController) {
                self.friendPickerViewController = [[CreateEventFriendPickerViewController alloc]
                                                   initWithEventModel:self.createEventModel];
            }
            
            [self.tableViewController.navigationController pushViewController:self.friendPickerViewController
                                                                     animated:YES];
            
            
        }
        
    } else if (indexPath.section == 2) {
        
        [self.tableViewController.navigationController pushViewController:self.dataSource.privacyViewController
                                                                 animated:YES];
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath compare:[NSIndexPath indexPathForRow:1 inSection:0]] == NSOrderedSame) {
        return (kDefaultTableCellHeight * 2);
    }
    
    return kDefaultTableCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 6.1) {
        return kTableCellMarginiOS7;
    }
    return kTableCellMargin;
}

#pragma mark cancel method
- (void)cancel:(id)sender
{
    [self.tableViewController.navigationController popViewControllerAnimated:YES];
}

#pragma mark create Event

- (void)createEvent:(id)sender
{
    __block UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *spinnerButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    
    self.tableViewController.navigationItem.rightBarButtonItem = spinnerButtonItem;
    [spinner startAnimating];
    
    if (self.existingEventId)
    {
        NSDictionary *changedEventParameters = [self.createEventModel
                                                onlyParametersChangedFromStoredModel:self.storedEventModel];
        if (changedEventParameters) {
            [[ParseDataStore sharedStore] editEventWithParameters:changedEventParameters eventId:self.existingEventId completion:^{
                
                __block NSMutableDictionary *completeNewEventDetails = [[NSMutableDictionary alloc] init];;
                [[ParseDataStore sharedStore] fetchEventListDataForListKey:kHostEventsKey completion:^(NSArray *eventsList) {
                    [[EventsListController sharedListController] refreshTableViewForEventsListKey:kHostEventsKey
                                                                                    newEventsList:eventsList
                                                                      endRefreshForRefreshControl:nil];
                    for (NSDictionary *event in eventsList) {
                        if ([event[@"id"] isEqualToString:self.existingEventId]) {
                            [completeNewEventDetails addEntriesFromDictionary:event];
                        }
                    }
                    
                    [[ParseDataStore sharedStore] fetchEventDetailsForEvent:self.existingEventId useCache:NO completion:^(NSDictionary *eventDetails) {
                        [spinner stopAnimating];
                        [spinner removeFromSuperview];
                        [completeNewEventDetails addEntriesFromDictionary:eventDetails];
                        [self.detailViewController refreshDetailsViewWithCompleteDetails:completeNewEventDetails];
                        
                        [self.tableViewController.navigationController popViewControllerAnimated:YES];
                    }];
                    
                }];
            }];
            
        } else {
            
            [spinner stopAnimating];
            [spinner removeFromSuperview];
            [self.tableViewController.navigationController popViewControllerAnimated:YES];
            
        }
        
    }
    else
    {
        [[ParseDataStore sharedStore] createEventWithParameters:self.createEventModel.validEvent completion:^(NSString *newEventId) {
            
            if (self.createEventModel.invitedFriendIds) {
                [[ParseDataStore sharedStore] inviteFriendsToEvent:newEventId
                                                       withFriends:self.createEventModel.invitedFriendIds
                                                        completion:nil];
            }
            
            [[ParseDataStore sharedStore] fetchEventListDataForListKey:kHostEventsKey completion:^(NSArray *eventsList) {
                [self.eventsListController refreshTableViewForEventsListKey:kHostEventsKey
                                                              newEventsList:eventsList
                                                endRefreshForRefreshControl:nil];
            }];
            
            
            [[ParseDataStore sharedStore] fetchPartialEventDetailsForNewEvent:newEventId completion:^(NSDictionary *eventDetails) {
                [spinner stopAnimating];
                [self.tableViewController.navigationController popViewControllerAnimated:NO];
                [self.eventsListController pushEventDetailsViewControllerWithPartialDetails:eventDetails
                                                                                   isActive:NO
                                                                                     isHost:YES
                                                                                 hasReplied:YES];
            }];
            
        }];
    }

}


@end
