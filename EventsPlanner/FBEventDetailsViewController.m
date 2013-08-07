
//
//  FBEventDetailsViewController.m
//  EventsPlanner
//
//  Created by Ashwin Murthy on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBEventDetailsViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "MKGeocodingService.h"
#import "FBEventsDetailsTableDataSource.h"
#import "ActiveEventMapViewController.h"
#import "UIImage+ImageCrop.h"
#import "ParseDataStore.h"
#import "FBEventStatusTableController.h"

static const float kLatitudeAdjustment = 0.0008;
static const float kLongitudeAsjustment = 0;

@interface FBEventDetailsViewController () <UITextFieldDelegate, UIAlertViewDelegate>
{
    CLLocationCoordinate2D venueLocationCoordinate;
    NSString *_venueLocationString;
    CLLocationCoordinate2D _venueLocation;
    NSMutableDictionary *_guestDetailsDictionary;
    
    NSMutableArray *_attendingFriends;
    
    UIScrollView *_scrollView;
    UIImageView *_coverImageView;
    UILabel *_titleLabel;
    UIView *_buttonHolder;
    UITableView *_detailsTable;
    FBEventsDetailsTableDataSource *_dataSource;
    __strong GMSMapView *_mapView;
    
    __strong FBEventStatusTableController *_statusTableController;
    

    UITabBarItem *_item;
    UIImage *_briefcase;

}

@property (nonatomic, getter = isHost) BOOL host;

@property (nonatomic, strong) NSMutableDictionary *eventDetails;
@property (nonatomic, strong) NSMutableArray *friendsIDArray;

@property (nonatomic, strong) NSMutableDictionary *dimensionsDict;
@property (nonatomic, strong) NSMutableDictionary *viewsDictionary;

@property (nonatomic, strong) UIButton *startTrackingButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

- (void)moveMapCameraAndPlaceMarkerAtCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)loadMapView:(id)sender;

- (void)changeRsvpStatus:(id)sender;

@end

@implementation FBEventDetailsViewController

- (id)initWithPartialDetails:(NSDictionary *)partialDetails isHost:(BOOL)isHost
{
    self = [super init];
    if (self) {
        
        _host = isHost;
        _eventDetails = [[NSMutableDictionary alloc] initWithDictionary:partialDetails];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [self setViewPartialEventDetails];
    
    [[ParseDataStore sharedStore] event:_eventDetails[@"id"] fetchDetailsWithCompletion:^(NSDictionary *eventDetails) {
        [[self eventDetails] addEntriesFromDictionary:eventDetails];
        [self setViewCompleteEventDetails];
    }];
}

- (void)setViewPartialEventDetails
{
    _dimensionsDict = [[NSMutableDictionary alloc]
                       initWithDictionary:@{ @"screenWidth":[NSNumber numberWithFloat:
                                                             [UIScreen mainScreen].bounds.size.width] }];
    
    _viewsDictionary = [[NSMutableDictionary alloc] init];
    
    // Creating new scroll view
    _scrollView = [[UIScrollView alloc] init];
    [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_scrollView setBackgroundColor:[UIColor whiteColor]];
    
    [self.view addSubview:_scrollView];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_scrollView":_scrollView }];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_scrollView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:_viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:_viewsDictionary]];
    
    
    // Initializing eventImageView and setting its UIImage
    _coverImageView = [[UIImageView alloc] init];
    [_coverImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [_scrollView addSubview:_coverImageView];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_coverImageView":_coverImageView }];
    [_scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_coverImageView]|"
                                                                        options:0
                                                                        metrics:0
                                                                          views:_viewsDictionary]];
    [_scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_coverImageView]"
                                                                        options:0
                                                                        metrics:0
                                                                          views:_viewsDictionary]];
    [_coverImageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_coverImageView(120)]"
                                                                            options:0
                                                                            metrics:0
                                                                              views:_viewsDictionary]];
    [_coverImageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_coverImageView(screenWidth)]"
                                                                            options:0
                                                                            metrics:_dimensionsDict
                                                                              views:_viewsDictionary]];
    
    //creating event title label and features
    NSString *eventTitle = [_eventDetails objectForKey:@"name"];
    _titleLabel = [[UILabel alloc] init];
    [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_titleLabel setBackgroundColor:[UIColor clearColor]];
    [_titleLabel setText:eventTitle];
    [_titleLabel setUserInteractionEnabled:NO];
    
    CGFloat fontSize = MIN(24,625/[eventTitle length]);
    UIFont *textFont = [UIFont fontWithName:@"Helvetica Neue" size:fontSize];
    
    [_titleLabel setTextColor:[UIColor whiteColor]];
    [_titleLabel setFont:textFont];
    [_titleLabel setTextAlignment:NSTextAlignmentLeft];
    
    [_coverImageView addSubview:_titleLabel];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_titleLabel":_titleLabel }];
    [_coverImageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_titleLabel]-|"
                                                                            options:0
                                                                            metrics:0
                                                                              views:_viewsDictionary]];
    [_coverImageView addConstraint:[NSLayoutConstraint constraintWithItem:_coverImageView
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_titleLabel
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1.0
                                                                 constant:0]];
    
    // Adding tapGestureRecognizer to eventImageView
    [_coverImageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *eventImageRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(tap:)];
    [eventImageRecognizer setNumberOfTapsRequired:1];
    [_coverImageView addGestureRecognizer:eventImageRecognizer];
    
    
    _buttonHolder = [[UIView alloc] init];
    [_buttonHolder setBackgroundColor:[UIColor whiteColor]];
    [_buttonHolder setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [_scrollView addSubview:_buttonHolder];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_buttonHolder":_buttonHolder }];
    [_scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_buttonHolder]|"
                                                                        options:0
                                                                        metrics:0
                                                                          views:_viewsDictionary]];
    [_scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_coverImageView][_buttonHolder]"
                                                                        options:0
                                                                        metrics:0
                                                                          views:_viewsDictionary]];
    [_buttonHolder addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_buttonHolder(screenWidth)]"
                                                                          options:0
                                                                          metrics:_dimensionsDict
                                                                            views:_viewsDictionary]];
    [_buttonHolder addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_buttonHolder(40)]"
                                                                          options:0
                                                                          metrics:0
                                                                            views:_viewsDictionary]];
    
    UIButton *inviteButton = [[UIButton alloc] init];
    [inviteButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    inviteButton.showsTouchWhenHighlighted = YES;
    [inviteButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    [inviteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [inviteButton addTarget:self action:@selector(startButtonTouch:) forControlEvents:UIControlEventTouchDown];
    [inviteButton addTarget:self action:@selector(inviteFriends:) forControlEvents:UIControlEventTouchUpInside];
    [inviteButton addTarget:self action:@selector(resetButtonBackGroundColor:)
           forControlEvents:UIControlEventTouchUpOutside];
    [inviteButton setTitle:@"Invite" forState:UIControlStateNormal];
    
    UIButton *rsvpStatusButton = [[UIButton alloc] init];
    [rsvpStatusButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    rsvpStatusButton.showsTouchWhenHighlighted = YES;
    [rsvpStatusButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    [rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [rsvpStatusButton addTarget:self action:@selector(startButtonTouch:) forControlEvents:UIControlEventTouchDown];
    [rsvpStatusButton addTarget:self action:@selector(changeRsvpStatus:) forControlEvents:UIControlEventTouchUpInside];
    [rsvpStatusButton addTarget:self action:@selector(resetButtonBackGroundColor:)
               forControlEvents:UIControlEventTouchUpOutside];
    [rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [rsvpStatusButton setTitle:@"RSVP Status" forState:UIControlStateNormal];
    
    [_buttonHolder addSubview:inviteButton];
    [_buttonHolder addSubview:rsvpStatusButton];
    [_viewsDictionary addEntriesFromDictionary:@{ @"inviteButton":inviteButton }];
    [_viewsDictionary addEntriesFromDictionary:@{ @"rsvpStatusButton":rsvpStatusButton }];
    
    [_buttonHolder addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|[inviteButton]|"
                                   options:0
                                   metrics:0
                                   views:_viewsDictionary]];
    [_buttonHolder addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|[rsvpStatusButton]|"
                                   options:0
                                   metrics:0
                                   views:_viewsDictionary]];
    [_buttonHolder addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|[inviteButton][rsvpStatusButton]|"
                                   options:0
                                   metrics:0
                                   views:_viewsDictionary]];
    [_buttonHolder addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"[inviteButton(==rsvpStatusButton)]"
                                   options:0
                                   metrics:0
                                   views:_viewsDictionary]];
    
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [_spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [_scrollView addSubview:_spinner];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_spinner":_spinner }];
    [_scrollView addConstraints:[NSLayoutConstraint
                                 constraintsWithVisualFormat:@"V:[_buttonHolder]-20-[_spinner]"
                                 options:0
                                 metrics:0
                                 views:_viewsDictionary]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:_spinner
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    [_spinner startAnimating];
    
}

- (void)setViewCompleteEventDetails
{
    // Removing spinner
    [_spinner stopAnimating];
    [_spinner removeFromSuperview];
    _spinner = nil;
    
    //initializing mapView and setting coordinates of location
    _mapView = [[GMSMapView alloc]
                initWithFrame:CGRectMake(0, 0, [_dimensionsDict[@"screenWidthWithMargin"] floatValue], 100)];
    
    NSDictionary *venueDict = _eventDetails[@"venue"];
    NSString *locationName = _eventDetails[@"location"];
    if (venueDict[@"latitude"]) {
        NSString *latString = venueDict[@"latitude"];
        NSString *lngString = venueDict[@"longitude"];
        double latitude = [latString doubleValue];
        double longitude = [lngString doubleValue];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        _venueLocation = coordinate;
        [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
  
    } else {
        
        MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
        
        [geocoder fetchGeocodeAddress:locationName completion:^(NSDictionary *geocode, NSError *error) {
            CLLocationCoordinate2D coordinate = [((CLLocation *)geocode[@"location"]) coordinate];
            _venueLocation = coordinate;
            [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
        }];
        
    }
    
    // initializing data source for table view
    _dataSource = [[FBEventsDetailsTableDataSource alloc] initWithEventDetails:_eventDetails];
    
    //creating table view with event details and setting data source
    _detailsTable = [[UITableView alloc] init];
    [_detailsTable setBackgroundColor:[UIColor whiteColor]];
    [_detailsTable setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_detailsTable setDataSource:_dataSource];
    [_detailsTable setTableHeaderView:_mapView];
    
    //setting some UI aspects of tableview
    [_detailsTable.layer setCornerRadius:3];
    [_detailsTable.layer setBorderWidth:0.5];
    [_detailsTable.layer setBorderColor: [[UIColor colorWithWhite:0 alpha:0.3] CGColor]];
    [_detailsTable setUserInteractionEnabled:NO];
    [_detailsTable setScrollEnabled:NO];
    
    [_dimensionsDict
     addEntriesFromDictionary:@{ @"screenWidthWithMargin":[NSNumber numberWithFloat:
                                                           ([UIScreen mainScreen].bounds.size.width - 40.0)],
                                 
                                 @"detailsTableContentHeight":[NSNumber numberWithFloat:
                                                               [_detailsTable contentSize].height] }];
    

    
    [_scrollView addSubview:_detailsTable];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_detailsTable":_detailsTable }];
    
    if ([self isHost]) {
        
        _startTrackingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_startTrackingButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_startTrackingButton setTitle:@"Start Tracking" forState:UIControlStateNormal];
        [_startTrackingButton addTarget:self
                                 action:@selector(loadMapView:)
                       forControlEvents:UIControlEventTouchUpInside];
        
        [_scrollView addSubview:_startTrackingButton];
        [_viewsDictionary addEntriesFromDictionary:@{ @"_startTrackingButton":_startTrackingButton }];
        
        NSString *verticalLayout =
            @"V:[_buttonHolder]-[_startTrackingButton(40)]-[_detailsTable(detailsTableContentHeight)]-|";
        [_scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:verticalLayout
                                     options:0
                                     metrics:_dimensionsDict
                                     views:_viewsDictionary]];
        [_scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:|-20-[_startTrackingButton(screenWidthWithMargin)]-20-|"
                                     options:0
                                     metrics:_dimensionsDict
                                     views:_viewsDictionary]];
        
    }
    else {
        
        [_scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"V:[_buttonHolder]-20-[_detailsTable(detailsTableContentHeight)]-|"
                                     options:0
                                     metrics:_dimensionsDict
                                     views:_viewsDictionary]];
        
    }
    
        [_scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:|-20-[_detailsTable(screenWidthWithMargin)]-20-|"
                                     options:0
                                     metrics:_dimensionsDict
                                     views:_viewsDictionary]];
}


/*
- (void)setViewCompleteEventDetails
{
        _eventDetails = eventDetails;
        
        FBGraphObject *fbGraphObj = (FBGraphObject *)_eventDetails;
        
        _dataSource = [[FBEventsDetailsTableDataSource alloc] initWithEventDetails:[[NSMutableDictionary alloc] initWithDictionary:details]];
    
        NSArray *attendingFriends = fbGraphObj[@"attending"][@"data"];
        
        
        _venueLocationString= (NSString *)_eventDetails[@"location"];
        
        _friendsIDArray = [[NSMutableArray alloc] init];
        for (NSDictionary *friend in attendingFriends)
        {
            [_friendsIDArray addObject:(NSString *)friend[@"id"]];
        }
        
        NSString *path = [NSString stringWithFormat: @"%@?fields=attending.fields(id,name)",details[@"id"]];
        FBRequest *guestListRequest = [FBRequest requestForGraphPath:path];
        _guestDetailsDictionary = [[NSMutableDictionary alloc] init];
        
        [guestListRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            
            NSArray *queriedIdData = result[@"attending"][@"data"];
            for (NSDictionary *userDetails in queriedIdData) {
                
                NSString *guestID = userDetails[@"id"];
                NSMutableDictionary *details = [[NSMutableDictionary alloc] init];
                details[@"name"] = userDetails[@"name"];
                
                [_guestDetailsDictionary setObject:details forKey: guestID];
            }
//            [[ParseDataStore sharedStore] fetchLocationDataForIds:_guestDetailsDictionary];
        }];
    
}
 */

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
//    if (!(_eventDetails[@"location"]||_eventDetails[@"venue"][@"lattitude"])) {
//        __strong UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your Event Location Was Invalid" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Submit", nil];
//        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
//        [alert setDelegate:self];
//        UITextField *locationInputTextView = [alert textFieldAtIndex:0];
//        [locationInputTextView setPlaceholder:@"Please Enter a Location"];
//        [alert show];
//    }
    
    NSLog(@"%@", NSStringFromCGRect(_detailsTable.frame));
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
    UIImage *baseEventImage = _eventDetails[@"cover"];
    UIImage *scaledImage = [UIImage imageWithImage:baseEventImage
                                     scaledToWidth:[_dimensionsDict[@"screenWidth"] floatValue]];
    UIImage *croppedScaleImage = [UIImage imageWithImage:scaledImage
                                cropRectFromCenterOfSize:CGSizeMake(scaledImage.size.width, 120)];
    
    [_coverImageView setImage:croppedScaleImage];
    
    [super viewWillAppear:animated];
}

- (void)moveMapCameraAndPlaceMarkerAtCoordinate:(CLLocationCoordinate2D)coordinate
{
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude + kLatitudeAdjustment
                                                                longitude:coordinate.longitude + kLongitudeAsjustment
                                                                     zoom:14];
        [_mapView setCamera:camera];
    
        GMSMarker *marker = [[GMSMarker alloc] init];
        marker.position = coordinate;
        marker.map = _mapView;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *locationString = [alertView textFieldAtIndex:0].text;
    MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
    
    [geocoder fetchGeocodeAddress:locationString completion:^(NSDictionary *geocode, NSError *error) {
        CLLocationCoordinate2D coordinate = [((CLLocation *)geocode[@"location"]) coordinate];
        _venueLocation = coordinate;
        [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
        if (!coordinate.latitude) {
            [alertView show];
        }
        else {
            [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
            [_eventDetails setValue:locationString forKey:@"location"];
            [_dataSource updateObject:locationString forKey:@"location"];
            [_detailsTable reloadData];
        }
    }];
}

-(void) tap: (UIGestureRecognizer*) gr {
    //push new popover view with full image
}

-(void) startButtonTouch: (id) sender {
    //set button to be highlighted
    [sender setBackgroundColor: [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
}

-(void) inviteFriends: (id) sender {
    
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    FBFriendPickerViewController *friendPicker = [[FBFriendPickerViewController alloc] init];
    
    [friendPicker loadData];
    [friendPicker setTitle:@"Invite Friends"];
    [friendPicker presentModallyFromViewController:self animated:YES handler:^(FBViewController *sender, BOOL donePressed) {
    
        NSMutableArray *usersToInvite = [[NSMutableArray alloc] init];
        
        for (id<FBGraphUser> user in friendPicker.selection) {
            [usersToInvite addObject:(NSString *)user[@"id"]];
        }
        
        [[ParseDataStore sharedStore] event:_eventDetails[@"id"] inviteFriends:usersToInvite completion:nil];
        
    }];
    
}

- (void)changeRsvpStatus:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    void (^completionBlock)(NSString *newStatus) = (^(NSString *newStatus) {
        [[ParseDataStore sharedStore] event:_eventDetails[@"id"] changeRsvpStatusTo:newStatus completion:nil];
    });
    
    _statusTableController = [[FBEventStatusTableController alloc] initWithStatus:_eventDetails[@"rsvp_status"]
                                                                       completion:completionBlock];
    
    [self.navigationController pushViewController:[_statusTableController presentableViewController] animated:YES];
}

- (void) resetButtonBackGroundColor: (id) sender {
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
}

- (void)loadMapView:(id)sender
{
    [[ParseDataStore sharedStore] startTrackingMyLocation];
    UIViewController *statsController = [[UIViewController alloc]init];
    statsController.view=[[UIView alloc]init];
    
    _item= [statsController tabBarItem];
    _briefcase= [UIImage imageNamed:@"listFinal.png"];
    [_item setImage:_briefcase];

    
    
    UITabBarController *tabBarController=[[UITabBarController alloc]init];
    ActiveEventMapViewController *mapViewController = [[ActiveEventMapViewController alloc]
                                                       initWithGuestArray:_eventDetails[@"attending"][@"data"]
                                                       venueLocation:_venueLocation];
    [statsController setTitle:@"Stats"];
    
    
    [mapViewController setTitle:@"Map"];
    
    [tabBarController setViewControllers:@[mapViewController, statsController]];
    [[self navigationController] pushViewController:tabBarController animated:YES];
}

@end
