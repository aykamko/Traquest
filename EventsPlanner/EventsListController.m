//
//  EventsListController.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventsListController.h"
#import "EventsTableViewDataSource.h"
#import "FBGuestEventDetailsViewController.h"

@interface EventsListController() <UITableViewDelegate>

@property (nonatomic, strong) UITableViewController *tableViewController;
@property (nonatomic, strong) EventsTableViewDataSource *tableViewDataSource;
@property (nonatomic, strong) NSArray *hostEvents;
@property (nonatomic, strong) NSArray *guestEvents;
@property(nonatomic,strong) UIImage *background;
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

        
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"lemonlime" ofType:@"jpg"];
        NSLog(@"%@",imagePath);
        _background=[[UIImage alloc]init];
       _background = [UIImage imageWithContentsOfFile:imagePath];
  //    NSData *imageData=[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
//        UIImage *image=[UIImage imageWithData:imageData];
        _tableViewController.view.backgroundColor=[UIColor colorWithPatternImage:_background];
        //UIView *container=[[UIView alloc]init];
        UIBarButtonItem *barButton=[[UIBarButtonItem alloc]initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logUserOut:)];
        self.tableViewController.navigationItem.rightBarButtonItem=barButton;
        
    }
    return self;
}




-(IBAction)logUserOut:(id)sender{
    [PFUser logOut];
    [_tableViewController.navigationController popToRootViewControllerAnimated:YES];
    [PFQuery clearAllCachedResults];
     NSLog(@"lalal");

    
      
}


- (id)presentableViewController
{
    return [self tableViewController];
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *eventsArray;
    
    if ([indexPath section] == hostedEvent) {
        eventsArray = _hostEvents;
    }
    
    else if([indexPath section] == guestEvent){
        eventsArray = _guestEvents;
        
        NSDictionary *currentEventDetails = [eventsArray objectAtIndex:[indexPath row]];

//        NSLog(@"%@", currentEventDetails);
        
        FBGuestEventDetailsViewController *eventDetailsController = [[FBGuestEventDetailsViewController alloc] initWithEventDetails:currentEventDetails];
        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Events List"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
        
        [_tableViewController.navigationItem setBackBarButtonItem:backButton];
        
        [[_tableViewController navigationController] pushViewController:eventDetailsController animated:YES];

    }
}

@end
