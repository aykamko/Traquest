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


@property (nonatomic, weak) UITableViewController *tableActiveViewController;
@property (nonatomic, weak) UITableViewController *hostTableViewController;
@property (nonatomic, weak) UITableViewController *attendingTableViewController;
@property (nonatomic, weak) UITableViewController *maybeTableViewController;
@property (nonatomic, weak) UITableViewController *notRepliedTableViewController;

@property (nonatomic, weak) UITableViewController *selectedTableViewController;

@property (nonatomic, strong) EventsTableViewDataSource *tableActiveViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *hostTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *attendingTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *maybeTableViewDataSource;
@property (nonatomic, strong) EventsTableViewDataSource *notRepliedTableViewDataSource;

@property (nonatomic, strong) UITabBarController *tabBarController;

@property (nonatomic, weak) UIRefreshControl *hostRefreshControl;
@property (nonatomic, weak) UIRefreshControl *attendingRefreshControl;
@property (nonatomic, weak) UIRefreshControl *maybeRefreshControl;
@property (nonatomic, weak) UIRefreshControl *notRepliedRefreshControl;

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
    
        self.tabBarController = [self tabBarControllerWithInitializedTableViewControllers];
        
        self.selectedTableViewController = self.tableActiveViewController;
        
        _tabBarController.navigationItem.title = self.selectedTableViewController.title;
        UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                 style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(logUserOut:)];

        self.tabBarController.navigationItem.leftBarButtonItem = logoutButton;
  

        UIBarButtonItem *newEventButton = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                           target:self
                                           action:@selector(makeNewEvent:)];
        [logoutButton setTitleTextAttributes:@{ UITextAttributeFont: [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0] }
                                    forState:UIControlStateNormal];

        self.tabBarController.navigationItem.rightBarButtonItem = newEventButton;
        self.tabBarController.navigationItem.hidesBackButton = YES;
        self.tabBarController.navigationController.navigationBar.translucent = NO;
    }
    return self;
}
#pragma mark tabBar Controller Method
- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    self.selectedTableViewController = (UITableViewController *)viewController;
    _tabBarController.navigationItem.title = viewController.title;
}

- (id)presentableViewController
{
    
    return self.tabBarController;
}



#pragma mark Log out Method

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

- (void)pushEventDetailsViewControllerWithPartialDetails:(NSDictionary *)partialDetails
                                                isActive:(BOOL)active
                                                  isHost:(BOOL)isHost
                                              hasReplied:(BOOL)replied
{
    
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

- (FBEventDetailsViewController *)detailsViewControllerForEvent:(NSString *)eventId
{
    NSDictionary *chosenEvent;
    NSArray *possibleArrays = @[self.attendingEvents, self.maybeAttending];
    
    for (NSArray *eventArray in possibleArrays) {
        for (NSDictionary *event in eventArray) {
            if ([event[@"id"] isEqualToString:eventId]) {
                chosenEvent = event;
                break;
            }
        }
    }
    
    return [[FBEventDetailsViewController alloc] initWithPartialDetails:chosenEvent
                                                               isActive:YES
                                                                 isHost:NO
                                                             hasReplied:YES];
}


- (UITabBarController *)tabBarControllerWithInitializedTableViewControllers
{
    
    _tableActiveViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_allActiveEvents];
    _hostTableViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_hostEvents];
    _attendingTableViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_attendingEvents];
    _maybeTableViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_maybeAttending];
    _notRepliedTableViewDataSource = [[EventsTableViewDataSource alloc] initWithEventArray:_notReplyEvents];
    
    UITableViewController *tableActiveViewController = [[UITableViewController alloc]
                                                        initWithStyle:UITableViewStyleGrouped];
    [[tableActiveViewController tableView] setDelegate:self];
    [[tableActiveViewController tableView] setDataSource:_tableActiveViewDataSource];
    [tableActiveViewController setTitle:@"Active"];
    UIImage *clockIcon = [UIImage imageNamed:@"Clock.png"];
    [[tableActiveViewController tabBarItem] setImage: clockIcon];
    
    UITableViewController *hostTableViewController = [[UITableViewController alloc]
                                                      initWithStyle:UITableViewStyleGrouped];
    [[hostTableViewController tableView] setDelegate:self];
    [[hostTableViewController tableView] setDataSource:_hostTableViewDataSource];
    [hostTableViewController setTitle:@"Host"];
    UIImage *friendIcon = [UIImage imageNamed:@"hostIcon.png"];
    [[hostTableViewController tabBarItem] setImage:friendIcon];
    
    UIRefreshControl *hostRefreshControl = [[UIRefreshControl alloc] init];
    [hostRefreshControl addTarget:self
                           action:@selector(refreshTableViewUsingRefreshControl:)
                 forControlEvents:UIControlEventValueChanged];
    [hostTableViewController setRefreshControl:hostRefreshControl];
    self.hostRefreshControl = hostRefreshControl;
    
    UITableViewController *attendingTableViewController = [[UITableViewController alloc]
                                                           initWithStyle:UITableViewStyleGrouped];
    [[attendingTableViewController tableView] setDelegate:self];
    [[attendingTableViewController tableView] setDataSource:_attendingTableViewDataSource];
    [attendingTableViewController setTitle:@"Attending"];
    UIImage *checkIcon = [UIImage imageNamed:@"Checkmark.png"];
    [[attendingTableViewController tabBarItem] setImage:checkIcon];
    
    UIRefreshControl *attendingRefreshControl= [[UIRefreshControl alloc] init];
    [attendingRefreshControl addTarget:self
                                     action:@selector(refreshTableViewUsingRefreshControl:)
                           forControlEvents:UIControlEventValueChanged];
    [attendingTableViewController setRefreshControl:attendingRefreshControl];
    self.attendingRefreshControl = attendingRefreshControl;
    
    
    UITableViewController *maybeTableViewController = [[UITableViewController alloc]
                                                       initWithStyle:UITableViewStyleGrouped];
    [[maybeTableViewController tableView] setDelegate:self];
    [[maybeTableViewController tableView] setDataSource:_maybeTableViewDataSource];
    [maybeTableViewController setTitle:@"Maybe"];
    UIImage *questionIcon = [UIImage imageNamed:@"questionmark.png"];
    [[maybeTableViewController tabBarItem] setImage:questionIcon];
    
    UIRefreshControl *maybeRefreshControl = [[UIRefreshControl alloc] init];
    [maybeRefreshControl addTarget:self
                                 action:@selector(refreshTableViewUsingRefreshControl:)
                       forControlEvents:UIControlEventValueChanged];
    [maybeTableViewController setRefreshControl:maybeRefreshControl];
    self.maybeRefreshControl = maybeRefreshControl;
    
    UITableViewController *notRepliedTableViewController = [[UITableViewController alloc]
                                                            initWithStyle:UITableViewStyleGrouped];
    [[notRepliedTableViewController tableView] setDelegate:self];
    [[notRepliedTableViewController tableView] setDataSource:_notRepliedTableViewDataSource];
    [notRepliedTableViewController setTitle:@"No Reply"];
    UIImage *ellipsisIcon = [UIImage imageNamed:@"noReply.png"];
    [[notRepliedTableViewController tabBarItem] setImage:ellipsisIcon];
    
    UIRefreshControl *notRepliedRefreshControl = [[UIRefreshControl alloc] init];
    [notRepliedRefreshControl addTarget:self
                                      action:@selector(refreshTableViewUsingRefreshControl:)
                            forControlEvents:UIControlEventValueChanged];
    [notRepliedTableViewController setRefreshControl:self.notRepliedRefreshControl];
    self.notRepliedRefreshControl = notRepliedRefreshControl;
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    float statusBarSize = 20.0f;
    
    CGRect newFrame = tabBarController.view.frame;
    newFrame.size.height += statusBarSize;
    tabBarController.view.frame = newFrame;
    
    tabBarController.delegate = self;
    [tabBarController setViewControllers:@[tableActiveViewController,
                                                hostTableViewController,
                                                attendingTableViewController,
                                                maybeTableViewController,
                                                notRepliedTableViewController]];
    
    self.tableActiveViewController = tableActiveViewController;
    self.hostTableViewController = hostTableViewController;
    self.attendingTableViewController = attendingTableViewController;
    self.maybeTableViewController = maybeTableViewController;
    self.notRepliedTableViewController = notRepliedTableViewController;
    
    return tabBarController;
}


#pragma mark  Create New Event
- (IBAction)makeNewEvent:(id)sender
{
    self.createEventController = [[CreateEventController alloc] initWithListController:self];
    
    [self.tabBarController.navigationController
             pushViewController:self.createEventController.presentableViewController
             animated:YES];
}

#pragma mark Table View Methods

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


@end
