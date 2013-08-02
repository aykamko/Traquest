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

@interface EventsListController() <UITableViewDelegate>

@property (nonatomic, strong) UITableViewController *tableViewController;
@property (nonatomic, strong) EventsTableViewDataSource *tableViewDataSource;
@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *guestEvents;
-(IBAction)logUserOut:(id)sender;
@end

@implementation EventsListController

- (id)initWithHostEvents:hostEvents guestEvents:guestEvents
{
    self = [super init];
    if (self) {
        
        _hostEvents = hostEvents;
        _guestEvents = guestEvents;
        _tableViewDataSource = [[EventsTableViewDataSource alloc] initWithHostEvents:hostEvents guestEvents:guestEvents];
        
        _tableViewController=[[UITableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        [[_tableViewController tableView]setDelegate:self];
        [[_tableViewController tableView]setDataSource:_tableViewDataSource];
        [self setTableViewController:_tableViewController];

        UIImage *backgroundImage = [UIImage imageNamed:@"lemonlime.jpg"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:backgroundImage];
        
        _tableViewController.tableView.backgroundView = imageView;
        
        UIBarButtonItem *barButton=[[UIBarButtonItem alloc]initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logUserOut:)];
        self.tableViewController.navigationItem.rightBarButtonItem=barButton;
        
    }
    return self;
}




-(IBAction)logUserOut:(id)sender{
    
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"To login as another use, please logout of your Facebook App." message:Nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];

    
      
}


- (id)presentableViewController
{
    return [self tableViewController];
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *eventsArray;
    
    if ([indexPath section] == hostedEvent) {
        eventsArray = _hostEvents;
        
        NSDictionary *currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        
        NSLog(@"%@", currentEventDetails);
        
        
        FBEventDetailsViewController *hostEventDetailsController = [[FBEventDetailsViewController alloc] initWithGuestEventDetails:currentEventDetails isHost:YES];
        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        
        [_tableViewController.navigationItem setBackBarButtonItem:backButton];
        
        [[_tableViewController navigationController] pushViewController:hostEventDetailsController animated:YES];
    }
    
    else if([indexPath section] == guestEvent){
        eventsArray = _guestEvents;
        NSDictionary *currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];
        FBEventDetailsViewController *eventDetailsController = [[FBEventDetailsViewController alloc] initWithGuestEventDetails:currentEventDetails isHost:NO];

        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        [_tableViewController.navigationItem setBackBarButtonItem:backButton];
        [[_tableViewController navigationController] pushViewController:eventDetailsController animated:YES];

    }
}

@end
