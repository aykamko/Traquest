//
//  EventsListController.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventsListController.h"
#import "EventsTableViewDataSource.h"
#import "FBEventDetailsViewController.h"
#import "EventHeaderView.h"
#import "ParseDataStore.h"
#import "CreateEventController.h"

@interface EventsListController() <UITableViewDelegate, UITabBarControllerDelegate>

@property (nonatomic, strong) UITableViewController *tableViewController;
@property (nonatomic, strong) UITableViewController *tableHostViewController;
@property (nonatomic, strong) UITableViewController *tableGuestViewController;
@property (nonatomic, strong) UITableViewController *tableMaybeViewController;
@property (nonatomic, strong) UITableViewController *tableNoReplyViewController;
@property (nonatomic, strong) UITableViewController *tableActiveViewController;

@property (nonatomic, strong) EventsTableViewDataSource *tableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *tableHostViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *tableGuestViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *tableMaybeViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *tableNoReplyViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *tableActiveViewDataSource;

@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *guestEvents;
@property (nonatomic, strong) NSArray *noReplyEvents;
@property (nonatomic, strong) NSArray *maybeAttending;
@property (nonatomic, strong) NSArray *friendsArray;
@property (nonatomic, strong) FBEventDetailsViewController *eventDetailsViewController;
@property (nonatomic, strong) CreateEventController *createEventController;

@property (nonatomic, strong) UIBarButtonItem *logoutButton;

- (IBAction)logUserOut:(id)sender;

@end

@implementation EventsListController

- (id)initWithHostEvents:(NSArray *)hostEvents
             guestEvents:(NSArray *)guestEvents
           noReplyEvents:(NSArray *)noReplyEvents
          maybeAttending:(NSArray *)maybeAttending
{
    self = [super init];
    if (self) {
        
        _hostEvents = hostEvents;
        _guestEvents = guestEvents;
        _noReplyEvents = noReplyEvents;
        _maybeAttending = maybeAttending;
        
        _tableHostViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:hostEvents];
        _tableGuestViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:guestEvents];
        _tableMaybeViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:maybeAttending];
        _tableNoReplyViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:noReplyEvents];
        
//        _tableActiveViewDataSource = [[EventsTableViewDataSource alloc] initWithEvents:hostEvents];
        
//        _tableActiveViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
//        [[_tableActiveViewController tableView] setDelegate:self];
//        [[_tableActiveViewController tableView] setDataSource:_tableHostViewDataSource];
//        [_tableActiveViewController setTitle:@"Active"];
        
        _tableHostViewController = [[UITableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        [[_tableHostViewController tableView] setDelegate:self];
        [[_tableHostViewController tableView] setDataSource:_tableHostViewDataSource];
        [_tableHostViewController setTitle:@"Host"];
        
        _tableGuestViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [[_tableGuestViewController tableView] setDelegate:self];
        [[_tableGuestViewController tableView] setDataSource:_tableGuestViewDataSource];
        [_tableGuestViewController setTitle:@"Attending"];


        _tableMaybeViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [[_tableMaybeViewController tableView] setDelegate:self];
        [[_tableMaybeViewController tableView] setDataSource:_tableMaybeViewDataSource];
        [_tableMaybeViewController setTitle:@"Maybe"];
        
        _tableNoReplyViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [[_tableNoReplyViewController tableView] setDelegate:self];
        [[_tableNoReplyViewController tableView] setDataSource:_tableNoReplyViewDataSource];
        [_tableNoReplyViewController setTitle:@"No Reply"];

        _tabBarController = [[UITabBarController alloc] init];
        _tabBarController.delegate = self;
      
        [_tabBarController setViewControllers:@[_tableHostViewController,
                                                _tableGuestViewController,
                                                _tableMaybeViewController,
                                                _tableNoReplyViewController]];

        UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(logUserOut:)];
        self.tabBarController.navigationItem.leftBarButtonItem = logoutButton;
        
        UIBarButtonItem *newEventButton = [[UIBarButtonItem alloc] initWithTitle:@"+"
                                                                           style:UIBarButtonItemStyleBordered
                                                                          target:self
                                                                          action:@selector(makeNewEvent:)];
        self.tabBarController.navigationItem.rightBarButtonItem = newEventButton;
        
        self.tabBarController.navigationItem.hidesBackButton = YES;
        self.tableViewController.navigationController.navigationBar.translucent = NO;
    }
    return self;
}

- (IBAction)logUserOut:(id)sender{
    
  [[ParseDataStore sharedStore]logOutWithCompletion:^{
    [self.tabBarController.navigationController popViewControllerAnimated:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"To login as another user, please logout of Facebook in your settings."
                                                    message:Nil
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
      [alert show];
  }];
    
}

- (void)pushEventDetailsViewControllerWithPartialDetails:(NSDictionary *)partialDetails isHost:(BOOL)isHost hasReplied:(BOOL)replied
{
    self.eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:partialDetails
                                                                                            isHost:isHost
                                                                                        hasReplied:replied];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:nil
                                                                  action:nil];
    [self.tabBarController.navigationItem setBackBarButtonItem:backButton];
    
    [self.tabBarController.navigationController pushViewController:_eventDetailsViewController animated:YES];
}

- (IBAction)makeNewEvent:(id)sender
{
    self.createEventController = [[CreateEventController alloc] initWithListController:self];
    
    //TODO: set navigation bar translucency from within CreateEventController
    self.tabBarController.navigationController.navigationBar.translucent = NO;
    [self.tabBarController.navigationController
             pushViewController:self.createEventController.presentableViewController
             animated:YES];
}

- (id)presentableViewController
{
    return self.tabBarController;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // Hide footer
    return 90;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *eventsArray;
    NSDictionary *currentEventDetails;
    
    if ([_tabBarController selectedViewController] == _tableHostViewController) {
        
        eventsArray = _hostEvents;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isHost:YES hasReplied:YES];
        
    } else if ([_tabBarController selectedIndex] == 1) {
        
        eventsArray = _guestEvents;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isHost:NO hasReplied:YES];
        
    } else if ([_tabBarController selectedIndex] == 2) {
        
        eventsArray = _maybeAttending;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isHost:NO hasReplied:YES];
        
    } else if ([_tabBarController selectedIndex] == 3) {
        
        eventsArray = _noReplyEvents;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isHost:NO hasReplied:NO];
    }
    
}

@end
