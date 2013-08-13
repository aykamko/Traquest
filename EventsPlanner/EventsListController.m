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

@interface EventsListController() <UITableViewDelegate>

@property (nonatomic, strong) UITableViewController *tableViewController;
@property (nonatomic, strong) UITableViewController *tableHostViewController;
@property (nonatomic, strong) UITableViewController *tableGuestViewController;
@property (nonatomic, strong) UITableViewController *tableMaybeViewController;
@property (nonatomic, strong) UITableViewController *tableNoReplyViewController;

@property (nonatomic, strong) EventsTableViewDataSource *tableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *tableHostViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *tableGuestViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *tableMaybeViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *tableNoReplyViewDataSource;


@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *guestEvents;
@property (nonatomic, strong) NSArray *noReplyEvents;
@property (nonatomic, strong) NSArray *maybeAttending;
@property (nonatomic, strong) NSArray *friendsArray;
@property (nonatomic,strong) FBEventDetailsViewController *eventDetailsViewController;
@end

@implementation EventsListController

- (id)initWithHostEvents:hostEvents guestEvents:guestEvents noReplyEvents:noReplyEvents maybeAttending:maybeAttending
{
    self = [super init];
    if (self) {
        
        _hostEvents = hostEvents;
        _guestEvents = guestEvents;
        _noReplyEvents = noReplyEvents;
        _maybeAttending = maybeAttending;
        _tableViewDataSource = [[EventsTableViewDataSource alloc] initWithHostEvents:hostEvents guestEvents:guestEvents
                                noReplyEvents:noReplyEvents maybeAttending:maybeAttending];
        
        _tableHostViewDataSource = [[EventsTableViewDataSource alloc] initWithEvents:hostEvents];
        _tableGuestViewDataSource = [[EventsTableViewDataSource alloc] initWithEvents:guestEvents];
        _tableMaybeViewDataSource = [[EventsTableViewDataSource alloc] initWithEvents:maybeAttending];
        _tableNoReplyViewDataSource = [[EventsTableViewDataSource alloc] initWithEvents:noReplyEvents];
        
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0,0,1,90)];
        footer.backgroundColor = [UIColor clearColor];


        
        _tableHostViewController = [[UITableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        [[_tableHostViewController tableView] setDelegate:self];
        [[_tableHostViewController tableView] setDataSource:_tableHostViewDataSource];
        [_tableHostViewController setTitle:@"Host"];
        _tableHostViewController.tableView.tableFooterView = footer;
//        self.tableHostViewController.navigationItem.hidesBackButton = YES;
//        self.tableHostViewController.navigationController.navigationBar.translucent = NO;
        
        _tableGuestViewController = [[UITableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        [[_tableGuestViewController tableView] setDelegate:self];
        [[_tableGuestViewController tableView] setDataSource:_tableGuestViewDataSource];
        [_tableGuestViewController setTitle:@"Attending"];
        _tableGuestViewController.tableView.tableFooterView = footer;
        self.tableGuestViewController.navigationItem.hidesBackButton = YES;
        self.tableGuestViewController.navigationController.navigationBar.translucent = NO;


        _tableMaybeViewController = [[UITableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        [[_tableMaybeViewController tableView] setDelegate:self];
        [[_tableMaybeViewController tableView] setDataSource:_tableMaybeViewDataSource];
        [_tableMaybeViewController setTitle:@"Maybe"];
        _tableMaybeViewController.tableView.tableFooterView = footer;
        self.tableMaybeViewController.navigationItem.hidesBackButton = YES;
        self.tableMaybeViewController.navigationController.navigationBar.translucent = NO;

        
        _tableNoReplyViewController = [[UITableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        [[_tableNoReplyViewController tableView] setDelegate:self];
        [[_tableNoReplyViewController tableView] setDataSource:_tableNoReplyViewDataSource];
        [_tableNoReplyViewController setTitle:@"No Reply"];
        _tableNoReplyViewController.tableView.tableFooterView = footer;
        self.tableNoReplyViewController.navigationItem.hidesBackButton = YES;
        self.tableNoReplyViewController.navigationController.navigationBar.translucent = NO;

        _tabBarController = [[UITabBarController alloc] init];
      
        [_tabBarController setViewControllers:@[_tableHostViewController,_tableGuestViewController,_tableMaybeViewController,_tableNoReplyViewController]];


        _logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(logUserOut:)];
        
    }
    return self;
}

- (IBAction)logUserOut:(id)sender{
    
  [[ParseDataStore sharedStore]logOutWithCompletion:^{
    [self.tableViewController.navigationController popViewControllerAnimated:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"To login as another user, please logout of Facebook in your settings."
                                                    message:Nil
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
      [alert show];
  }];
    
}
   


- (id)presentableViewController
{
    return self.tabBarController;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // Hide footer
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0;
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
        
        _eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:currentEventDetails
                                                                                          isHost:YES hasReplied:YES];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        [_tableHostViewController.navigationItem setBackBarButtonItem:backButton];
        [[_tableHostViewController navigationController] pushViewController:_eventDetailsViewController animated:YES];
        
    } else if ([_tabBarController selectedIndex] == 1) {
        
        eventsArray = _guestEvents;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        _eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:currentEventDetails
                                                                                          isHost:NO hasReplied:YES];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        [_tableGuestViewController.navigationItem setBackBarButtonItem:backButton];
        [[_tableGuestViewController navigationController] pushViewController:_eventDetailsViewController animated:YES];
    } else if ([_tabBarController selectedIndex] == 2) {
        
        eventsArray = _maybeAttending;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        _eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:currentEventDetails
                                                                                            isHost:NO hasReplied:YES];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        [_tableMaybeViewController.navigationItem setBackBarButtonItem:backButton];
        [[_tableMaybeViewController navigationController] pushViewController:_eventDetailsViewController animated:YES];
    }
    else if ([_tabBarController selectedIndex]== 3) {
        
        eventsArray = _noReplyEvents;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        _eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:currentEventDetails
                                                                                            isHost:NO hasReplied:NO];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        [_tableNoReplyViewController.navigationItem setBackBarButtonItem:backButton];
        [[_tableNoReplyViewController navigationController] pushViewController:_eventDetailsViewController animated:YES];
    }
    
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
//                                                                   style:UIBarButtonItemStyleBordered
//                                                                  target:nil
//                                                                  action:nil];
//    [_tableViewController.navigationItem setBackBarButtonItem:backButton];
//    [[_tableViewController navigationController] pushViewController:_eventDetailsViewController animated:YES];
}

@end
