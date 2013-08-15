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

/*<<<<<<< HEAD
@property (nonatomic, strong) UITableViewController *hostTableViewController;
@property (nonatomic, strong) UITableViewController *attendingTableViewController;
@property (nonatomic, strong) UITableViewController *maybeTableViewController;
@property (nonatomic, strong) UITableViewController *notRepliedTableViewController;
@property (nonatomic, strong) UITableViewController *activeTableViewController;

@property (nonatomic, strong) UITableViewController *selectedTableViewController;

@property (nonatomic, strong) EventsTableViewDataSource *hostTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *attendingTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *maybeTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *notRepliedTableViewDataSource;


@property (nonatomic, strong) UITabBarController *tabBarController;

@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *attendingEvents;
@property (nonatomic, strong) NSArray *notRepliedEvents;
@property (nonatomic, strong) NSArray *maybeEvents;



@property (nonatomic, strong) NSArray *friendsArray;
=======*/

@property (nonatomic, strong) UITableViewController *tableActiveViewController;

@property (nonatomic, strong) UITableViewController *hostTableViewController;
@property (nonatomic, strong) UITableViewController *attendingTableViewController;
@property (nonatomic, strong) UITableViewController *maybeTableViewController;
@property (nonatomic, strong) UITableViewController *notRepliedTableViewController;

@property (nonatomic, strong) UITableViewController *selectedTableViewController;

@property (nonatomic, strong) EventsTableViewDataSource *tableActiveViewDataSource;

@property (nonatomic, strong) EventsTableViewDataSource *hostTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *attendingTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *maybeTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *notRepliedTableViewDataSource;

@property (nonatomic, strong) UITabBarController *tabBarController;


@property (nonatomic, strong) UIRefreshControl *hostRefreshControl;
@property (nonatomic, strong) UIRefreshControl *attendingRefreshControl;
@property (nonatomic, strong) UIRefreshControl *maybeRefreshControl;
@property (nonatomic, strong) UIRefreshControl *notRepliedRefreshControl;

@property (nonatomic, strong) NSArray *activeGuestEvents;
@property (nonatomic, strong) NSArray *activeHostEvents;
@property (nonatomic, strong) NSArray *allActiveEvents;
@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *attendingEvents;
@property (nonatomic, strong) NSArray *notReplyEvents;
@property (nonatomic, strong) NSArray *maybeAttending;

@property (nonatomic, strong) FBEventDetailsViewController *eventDetailsViewController;
@property (nonatomic, strong) CreateEventController *createEventController;

- (IBAction)logUserOut:(id)sender;

@end

@implementation EventsListController

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedListController];
}

+ (EventsListController *)sharedListController
{
    static EventsListController *sharedListController = nil;
    if (!sharedListController) {
        sharedListController = [[super allocWithZone:nil] init];
    }
    
    return sharedListController;
}


- (id)initWithActiveHostEvents:(NSArray *)activeHostEvents
             activeGuestEvents:(NSArray *)activeGuestEvents
                    hostEvents:(NSArray *)hostEvents
               attendingEvents:(NSArray *)attendingEvents
              notRepliedEvents:(NSArray *)noReplyEvents
                maybeAttending:(NSArray *)maybeAttending
{
    self = [super init];
    if (self) {
        
        _activeHostEvents = activeHostEvents;
        _activeGuestEvents = activeGuestEvents;
        NSMutableArray *tempActiveEvents = [activeHostEvents mutableCopy];
        [tempActiveEvents addObjectsFromArray:activeGuestEvents];
        _allActiveEvents = [NSArray arrayWithArray:tempActiveEvents];
        
        _hostEvents = hostEvents;

        _attendingEvents = attendingEvents;
        _notReplyEvents = noReplyEvents;
        _maybeAttending = maybeAttending;
    
        _trackingDict = [[NSMutableDictionary alloc]init];
        [self initializeViewControllers];
        
        _tabBarController = [[UITabBarController alloc] init];
        _tabBarController.delegate = self;
        
        [_tabBarController setViewControllers:@[_tableActiveViewController,
                                                _hostTableViewController,
                                                _attendingTableViewController,
                                                _maybeTableViewController,
                                                _notRepliedTableViewController]];
        
        self.selectedTableViewController = self.tableActiveViewController;

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
        self.tabBarController.navigationController.navigationBar.translucent = NO;
    }
    return self;
}

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    self.selectedTableViewController = (UITableViewController *)viewController;
}

- (void)refreshTableViewForEventsListKey:(NSString *)eventsListKey
                           newEventsList:(NSArray *)eventsList
             endRefreshForRefreshControl:(UIRefreshControl *)refreshControl
{
    UITableViewController *tableViewController;
    if ([eventsListKey isEqualToString:kHostEventsKey]) {
        tableViewController = self.hostTableViewController;
    } else if ([eventsListKey isEqualToString:kAttendingEventsKey]) {
        tableViewController = self.attendingTableViewController;
    } else if ([eventsListKey isEqualToString:kMaybeEventsKey] || [eventsListKey isEqualToString:kUnsureEventKey]) {
        tableViewController = self.maybeTableViewController;
    } else if ([eventsListKey isEqualToString:kNoReplyEventsKey]) {
        tableViewController = self.notRepliedTableViewController;
    } else {
        return;
    }
    
    ((EventsTableViewDataSource *)tableViewController.tableView.dataSource).eventArray = eventsList;
    [tableViewController.tableView reloadData];
    
    if (refreshControl) {
        [refreshControl endRefreshing];
    }
}

- (void)refreshTableViewUsingRefreshControl:(id)sender
{
    
    if ([sender isEqual:self.hostRefreshControl]) {
        
        [[ParseDataStore sharedStore] fetchEventListDataForListKey:kHostEventsKey completion:^(NSArray *eventsList) {
            [self refreshTableViewForEventsListKey:kHostEventsKey
                                     newEventsList:eventsList
                       endRefreshForRefreshControl:sender];
        }];
        
    } else if ([sender isEqual:self.attendingRefreshControl]) {
        
        [[ParseDataStore sharedStore] fetchEventListDataForListKey:kAttendingEventsKey completion:^(NSArray *eventsList) {
            [self refreshTableViewForEventsListKey:kAttendingEventsKey
                                     newEventsList:eventsList
                       endRefreshForRefreshControl:sender];
        }];
        
    } else if ([sender isEqual:self.maybeRefreshControl]) {
        
        [[ParseDataStore sharedStore] fetchEventListDataForListKey:kMaybeEventsKey completion:^(NSArray *eventsList) {
            [self refreshTableViewForEventsListKey:kMaybeEventsKey
                                     newEventsList:eventsList
                       endRefreshForRefreshControl:sender];
        }];
        
    } else if ([sender isEqual:self.notRepliedRefreshControl]) {
        
        [[ParseDataStore sharedStore] fetchEventListDataForListKey:kNoReplyEventsKey completion:^(NSArray *eventsList) {
            [self refreshTableViewForEventsListKey:kNoReplyEventsKey
                                     newEventsList:eventsList
                       endRefreshForRefreshControl:sender];
        }];
        
    }
}

- (IBAction)logUserOut:(id)sender{
    
    [[ParseDataStore sharedStore]logOutWithCompletion:^{
        [self.tabBarController.navigationController popViewControllerAnimated:YES];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"To login as another user, "
                                                                @"please logout of Facebook in your settings."
                                                        message:Nil
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }];
    
}

- (void)pushEventDetailsViewControllerWithPartialDetails:(NSDictionary *)partialDetails isActive:(BOOL)active isHost:(BOOL)isHost hasReplied:(BOOL)replied
{
    if ([_trackingDict objectForKey:partialDetails[@"id"]]) { //if user is already tracking
        self.eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:partialDetails
                                                                                              isActive:YES
                                                                                                isHost:isHost
                                                                                            hasReplied:replied];
    } else {
        
        self.eventDetailsViewController = [[FBEventDetailsViewController alloc] initWithPartialDetails:partialDetails
                                                                                              isActive:active
                                                                                                isHost:isHost
                                                                                            hasReplied:replied];
        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        [self.tabBarController.navigationItem setBackBarButtonItem:backButton];
        [self.tabBarController.navigationController pushViewController:_eventDetailsViewController animated:YES];
        
    }
}

#pragma mark  Create New Event
- (IBAction)makeNewEvent:(id)sender
{
    self.createEventController = [[CreateEventController alloc] initWithListController:self];
    
    //TODO: set navigation bar translucency from within CreateEventController
    self.tabBarController.navigationController.navigationBar.translucent = NO;
    [self.tabBarController.navigationController
             pushViewController:self.createEventController.presentableViewController
             animated:YES];
}

#pragma mark return tab Bar Controller
- (id)presentableViewController
{
    return self.tabBarController;
}

#pragma mark Table View Delegate Methods

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
    
    NSArray *eventsArray =
        ((EventsTableViewDataSource *)self.selectedTableViewController.tableView.dataSource).eventArray;
    NSDictionary *currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
    
    if (self.selectedTableViewController == self.tableActiveViewController) {
        
        if ([_activeHostEvents containsObject:currentEventDetails]) {
            [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isActive:YES isHost:YES hasReplied:YES];
        } else {
            [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isActive:YES isHost:NO hasReplied:YES];
        }
        
    } else if (self.selectedTableViewController == self.hostTableViewController) {
        
        [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isActive:NO isHost:YES hasReplied:YES];
    
    } else if (self.selectedTableViewController == self.attendingTableViewController) {
        
        [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isActive:NO isHost:NO hasReplied:YES];
        
    } else if (self.selectedTableViewController == self.maybeTableViewController) {
        
        [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isActive:NO isHost:NO hasReplied:YES];
    } else if (self.selectedTableViewController == self.notRepliedTableViewController) {
        
        [self pushEventDetailsViewControllerWithPartialDetails:currentEventDetails isActive:NO isHost:NO hasReplied:NO];
    }
    
    
}
#pragma mark initialize View Controllers
-(void)initializeViewControllers{
    
    _tableActiveViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_allActiveEvents];
    
    _hostTableViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_hostEvents];
    _attendingTableViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_attendingEvents];
    _maybeTableViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_maybeAttending];
    _notRepliedTableViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_notReplyEvents];
    
    _tableActiveViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [[_tableActiveViewController tableView] setDelegate:self];
    [[_tableActiveViewController tableView] setDataSource:_tableActiveViewDataSource];
    [_tableActiveViewController setTitle:@"Active"];
    
    _hostTableViewController = [[UITableViewController alloc]initWithStyle:UITableViewStyleGrouped];
    [[_hostTableViewController tableView] setDelegate:self];
    [[_hostTableViewController tableView] setDataSource:_hostTableViewDataSource];
    [_hostTableViewController setTitle:@"Host"];
    self.hostRefreshControl = [[UIRefreshControl alloc] init];
    [self.hostRefreshControl addTarget:self
                                action:@selector(refreshTableViewUsingRefreshControl:)
                      forControlEvents:UIControlEventValueChanged];
    [self.hostTableViewController setRefreshControl:self.hostRefreshControl];
    
    _attendingTableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [[_attendingTableViewController tableView] setDelegate:self];
    [[_attendingTableViewController tableView] setDataSource:_attendingTableViewDataSource];
    [_attendingTableViewController setTitle:@"Attending"];
    self.attendingRefreshControl= [[UIRefreshControl alloc] init];
    [self.attendingRefreshControl addTarget:self
                                     action:@selector(refreshTableViewUsingRefreshControl:)
                           forControlEvents:UIControlEventValueChanged];
    [self.attendingTableViewController setRefreshControl:self.attendingRefreshControl];
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0,0,1,90)];
    footer.backgroundColor = [UIColor clearColor];
    
    
    _maybeTableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [[_maybeTableViewController tableView] setDelegate:self];
    [[_maybeTableViewController tableView] setDataSource:_maybeTableViewDataSource];
    [_maybeTableViewController setTitle:@"Maybe"];
    self.maybeRefreshControl = [[UIRefreshControl alloc] init];
    [self.maybeRefreshControl addTarget:self
                                 action:@selector(refreshTableViewUsingRefreshControl:)
                       forControlEvents:UIControlEventValueChanged];
    [self.maybeTableViewController setRefreshControl:self.maybeRefreshControl];
    
    _notRepliedTableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [[_notRepliedTableViewController tableView] setDelegate:self];
    [[_notRepliedTableViewController tableView] setDataSource:_notRepliedTableViewDataSource];
    [_notRepliedTableViewController setTitle:@"No Reply"];
    self.notRepliedRefreshControl = [[UIRefreshControl alloc] init];
    [self.notRepliedRefreshControl addTarget:self
                                      action:@selector(refreshTableViewUsingRefreshControl:)
                            forControlEvents:UIControlEventValueChanged];
    [self.notRepliedTableViewController setRefreshControl:self.notRepliedRefreshControl];
    

}

@end
