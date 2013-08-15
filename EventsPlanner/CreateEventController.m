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

@property (nonatomic, strong) EventsListController *eventsListController;

@property (nonatomic, strong) CreateEventModel *createEventModel;

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
        
        self.dataSource = [[CreateEventTableViewDataSource alloc] initWithEventModel:self.createEventModel];
        
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

- (void)didSetNameAndDescription
{
    self.tableViewController.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)reloadTableView
{
    [self.tableViewController.tableView reloadData];
}

- (UIViewController *)presentableViewController
{
    return self.tableViewController;
}

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

- (void)cancel:(id)sender
{
    [self.tableViewController.navigationController popViewControllerAnimated:YES];
}

- (void)createEvent:(id)sender
{
    __block UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *spinnerButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    
    self.tableViewController.navigationItem.rightBarButtonItem = spinnerButtonItem;
    [spinner startAnimating];
    
    [[ParseDataStore sharedStore] createEventWithParameters:self.createEventModel.validEvent completion:^(NSString *newEventId) {
        
        if (self.createEventModel.invitedFriendIds) {
            [[ParseDataStore sharedStore] inviteFriendsToEvent:newEventId
                                                   withFriends:self.createEventModel.invitedFriendIds
                                                    completion:nil];
        }
        
        [[ParseDataStore sharedStore] fetchPartialEventDetailsForNewEvent:newEventId completion:^(NSDictionary *eventDetails) {
            [spinner stopAnimating];
            [self.tableViewController.navigationController popViewControllerAnimated:NO];
            [self.eventsListController pushEventDetailsViewControllerWithPartialDetails:eventDetails
                                                                                 isHost:YES
                                                                             hasReplied:YES];
        }];
        
        [[ParseDataStore sharedStore] fetchEventListDataForListKey:kHostEventsKey completion:^(NSArray *eventsList) {
            [self.eventsListController refreshTableViewForEventsListKey:kHostEventsKey
                                                          newEventsList:eventsList
                                            endRefreshForRefreshControl:nil];
        }];
        
    }];
}

@end
