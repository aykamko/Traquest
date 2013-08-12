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
@property (nonatomic, strong) EventsTableViewDataSource *tableViewDataSource;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *guestEvents;
@property (nonatomic, strong) NSArray *noReplyEvents;
@property (nonatomic, strong) NSArray *friendsArray;
@property (nonatomic,strong) FBEventDetailsViewController *eventDetailsViewController;
-(IBAction)logUserOut:(id)sender;
@end

@implementation EventsListController

- (id)initWithHostEvents:hostEvents guestEvents:guestEvents noReplyEvents:(NSArray *)noReplyEvents
{
    self = [super init];
    if (self) {
        
        _hostEvents = hostEvents;
        _guestEvents = guestEvents;
        _noReplyEvents = noReplyEvents;
        _tableViewDataSource = [[EventsTableViewDataSource alloc] initWithHostEvents:hostEvents
                                                                         guestEvents:guestEvents
                                                                        noReplyEvents:noReplyEvents];
        
        _tableViewController = [[UITableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        [[_tableViewController tableView] setDelegate:self];
        [[_tableViewController tableView] setDataSource:_tableViewDataSource];
        

        

        
        
        UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(logUserOut:)];
        self.tableViewController.navigationItem.rightBarButtonItem = logoutButton;
        self.tableViewController.navigationItem.hidesBackButton = YES;
        self.tableViewController.navigationController.navigationBar.translucent = NO;
        
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
    return [self tableViewController];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    EventHeaderView *headerView = [[EventHeaderView alloc] init];
    
    NSString *headerText;
    switch (section) {
        case 0: {
            headerText = @"Events You're Hosting";
            break;
        } case 1: {
            headerText = @"Events You're Invited To";
            break;
        }  case 2: {
            headerText = @"Events You Haven't Replied To";
            break;
        }
        default: {
            headerText = @"";
        }
    }
    [headerView setText:headerText];
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *eventsArray;
    NSDictionary *currentEventDetails;
    
    if (indexPath.section == 0) {
        
        eventsArray = _hostEvents;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        _eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:currentEventDetails
                                                                                          isHost:YES hasReplied:YES];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        [_tableViewController.navigationItem setBackBarButtonItem:backButton];
        [[_tableViewController navigationController] pushViewController:_eventDetailsViewController animated:YES];
        
    } else if (indexPath.section == 1) {
        
        eventsArray = _guestEvents;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        _eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:currentEventDetails
                                                                                          isHost:NO hasReplied:YES];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        [_tableViewController.navigationItem setBackBarButtonItem:backButton];
        [[_tableViewController navigationController] pushViewController:_eventDetailsViewController animated:YES];
    } else if (indexPath.section == 2) {
        
        eventsArray = _noReplyEvents;
        currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        _eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:currentEventDetails
                                                                                            isHost:NO hasReplied:NO];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        [_tableViewController.navigationItem setBackBarButtonItem:backButton];
        [[_tableViewController navigationController] pushViewController:_eventDetailsViewController animated:YES];
    }
    
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
//                                                                   style:UIBarButtonItemStyleBordered
//                                                                  target:nil
//                                                                  action:nil];
//    [_tableViewController.navigationItem setBackBarButtonItem:backButton];
//    [[_tableViewController navigationController] pushViewController:_eventDetailsViewController animated:YES];
}

@end
