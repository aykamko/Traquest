//
//  ActiveEventsStatsViewController.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "ActiveEventsStatsViewController.h"
#import "ParseDataStore.h"
#import "UIImage+ImageCrop.h"

@interface ActiveEventsStatsViewController ()

@property (nonatomic,strong) NSString *eventID;
@property CLLocationCoordinate2D venueLocation;

@end

@implementation ActiveEventsStatsViewController


-(id)initWithEventId:(NSString *)eventId venueLocation:(CLLocationCoordinate2D)venueLocation{
    
    self = [super init];
    if(self){
        self.eventID = eventId;
        self.venueLocation = venueLocation;
        self.statistics = [[NSArray alloc] init];
        self.statisticsKeys = @[@"# Guests Allowing Tracking",
                                @"# Guests Arrived",
                                @"# Guests Departed",
                                @"ETA of Half the Guests",
                                @"Average Distance",
                                @"Median Distance",
                                @"Average Speed"];
        
        UIView *footer = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 1, 90)];
        footer.backgroundColor  = [UIColor clearColor];
        self.tableView.tableFooterView = footer; 
        self.tableView.scrollEnabled = YES;
        self.tableView.separatorColor = [UIColor grayColor];
        [self.tableView setBackgroundColor:[UIColor whiteColor]];
   
        UITabBarItem *icon = [self tabBarItem];
        [icon setImage:[UIImage imageNamed:@"listFinal.png"]];
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        [super viewDidLoad];

    }
    return self;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
    [super viewWillAppear:animated];
}


-(void)reload{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark TableView Methods

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section  {
    return @"Stats";
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.statistics count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identifier = [NSString stringWithFormat:@"Cell %d", indexPath.row];
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    cell = nil;
    
    cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"statsCell"];
    cell.backgroundColor = [UIColor clearColor];
    
    UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, 300, 25)];
    title.backgroundColor = [UIColor clearColor];
    title.font =[UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    
    UILabel *description = [[UILabel alloc]initWithFrame:CGRectMake(10, 35, 300, 20)];
    description.backgroundColor  = [UIColor clearColor];
    [cell setUserInteractionEnabled:NO];
    
    [title setText:self.statisticsKeys[[indexPath row]]];
    
    if (self.statistics) {
        [description setText:self.statistics[[indexPath row]]];
    } else {
        [description setText:@"Unavailable"];
    }
    
    [cell addSubview:title];
    [cell addSubview:description];
    
    return cell;
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath   {
    return 100;
}

- (void)updateStatistics {
    NSDictionary *cloudFunctionParameters = @{@"eventId": self.eventID,
                                              @"currentTime": [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate]],
                                              @"latitude": [NSNumber numberWithDouble:self.venueLocation.latitude],
                                              @"longitude": [NSNumber numberWithDouble:self.venueLocation.longitude]};
    
    [PFCloud callFunctionInBackground:@"calculateStatistics" withParameters:cloudFunctionParameters block:^(id object, NSError *error) {
        if (![object isEqual:[NSNull null]]) {
            NSMutableArray *tempStatistics = [[NSMutableArray alloc] init];
            
            [tempStatistics addObject:[NSString stringWithFormat:@"%d", [object[@"numberOfUsers"] intValue]]];
            [tempStatistics addObject:[NSString stringWithFormat:@"%d", [object[@"numberArrived"] intValue]]];
            [tempStatistics addObject:[NSString stringWithFormat:@"%d", [object[@"numberDeparted"] intValue]]];
            
            [tempStatistics addObject:[NSString stringWithFormat:@"%.3f Minutes", [object[@"estimatedArrival"] floatValue]]];
            [tempStatistics addObject:[NSString stringWithFormat:@"%.3f Miles", [object[@"averageDistance"] floatValue]]];
            [tempStatistics addObject:[NSString stringWithFormat:@"%.3f Miles", [object[@"medianDistance"] floatValue]]];
            [tempStatistics addObject:[NSString stringWithFormat:@"%.3f MPH", [object[@"averageVelocity"] floatValue]]];
            
            self.statistics = [tempStatistics copy];
            [self.tableView reloadData];

        } else {
            self.statistics = nil;
        }
    }];
}

#pragma mark fetching GeoPoints
- (void)updateAllowedUserLocations:(NSDictionary *) allowedLocations anonLocations: (NSDictionary *) anonLocations {
    
}

@end
