
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
#import "FBEventDetailsTableDataSource.h"
#import "ActiveEventMapViewController.h"
#import "UIImage+ImageCrop.h"
#import "ParseDataStore.h"
#import "FBEventStatusTableController.h"
#import "FBEventDetailsTableDelegate.h"
#import "ActiveEventsStatsViewController.h"
#import "EventsListController.h"
static const float TrackingButtonFontSize = 20.0;
static const float TableViewSideMargin = 12.0;
static const float kLatitudeAdjustment = 0.0008;
static const float kLongitudeAsjustment = 0;

static NSInteger const kActionSheetCancelButtonIndex = 3;

@interface FBEventDetailsViewController () <UITextFieldDelegate, UIAlertViewDelegate, MKMapViewDelegate>
{
    CLLocationCoordinate2D _venueLocation;
    UITabBarController *_tabBarController;
    UIScrollView *_scrollView;
    UIImageView *_coverImageView;
    UILabel *_titleLabel;
    UIView *_buttonHolder;
    UITableView *_detailsTable;
    
    BOOL alreadyTracking;
    
    FBEventDetailsTableDataSource *_dataSource;
    __strong MKMapView *_mapView;

       ActiveEventsStatsViewController *_statsViewController;
    __strong FBEventStatusTableController *_statusTableController;
    ActiveEventMapViewController *_mapViewController;

    UITabBarItem *_item;
    UIImage *_briefcase;
    UIView *_transparentView;
    UIView *_wrapper;
    UITapGestureRecognizer *_singleFingerTap ;

}

@property (nonatomic, strong) NSArray *verticalLayoutContraints;

@property (nonatomic,strong) NSString *layoutConstraint;

@property (nonatomic, strong) NSString *status;

@property (nonatomic, getter = isTracking) BOOL tracking;
@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic, getter = isHost) BOOL host;
@property (nonatomic, getter = hasReplied) BOOL replied;

@property (nonatomic, strong) NSMutableDictionary *eventDetails;

@property (nonatomic, strong) UIButton *rsvpStatusButton;

@property (nonatomic, strong) NSMutableDictionary *dimensionsDict;
@property (nonatomic, strong) NSMutableDictionary *viewsDictionary;
@property (nonatomic, strong) UIButton *startTrackingButton;
@property (nonatomic, strong) UIButton *stopTrackingButton;
@property (nonatomic, strong) UIButton *viewMapButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic, strong) FBEventDetailsTableDelegate *detailsTableDelegate;

- (void)loadMapView:(id)sender;

- (void)changeRsvpStatus:(id)sender;

@end

@implementation FBEventDetailsViewController

- (id)initWithPartialDetails:(NSDictionary *)partialDetails isActive:(BOOL)active isHost:(BOOL)isHost hasReplied:(BOOL)hasReplied
{
    self = [super init];
    if (self) {
        
        _active = active;
        _host = isHost;
        _replied = hasReplied;
        _eventDetails = [[NSMutableDictionary alloc] initWithDictionary:partialDetails];
        
        // By default
        self.tracking = NO;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [self setViewPartialEventDetails];
    
    [[ParseDataStore sharedStore] fetchTrackingStatusForEvent:self.eventDetails[@"id"] completion:^(BOOL isTracking) {
        
        self.tracking = isTracking;
        
        [[ParseDataStore sharedStore] fetchEventDetailsForEvent:_eventDetails[@"id"] completion:^(NSDictionary *eventDetails) {
            
            [[self eventDetails] addEntriesFromDictionary:eventDetails];
            [self setViewCompleteEventDetails];
            [_detailsTable setNeedsDisplay];
            
        }];
    }];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    UIImage *baseEventImage = _eventDetails[@"cover"];
    
    if (!baseEventImage) {
        _eventDetails[@"cover"] = [UIImage imageNamed:@"eventCoverPhoto.png"];
        baseEventImage = _eventDetails[@"cover"];
    }
    
    UIImage *scaledImage = [UIImage imageWithImage:baseEventImage
                                     scaledToWidth:[_dimensionsDict[@"screenWidth"] floatValue]];
    UIImage *croppedScaleImage = [UIImage imageWithImage:scaledImage
                                cropRectFromCenterOfSize:CGSizeMake(scaledImage.size.width, 120)];
    
    [_coverImageView setImage:croppedScaleImage];
    
    [super viewWillAppear:animated];
}


-(void) tap: (UIGestureRecognizer*) gr {
    //push new popover view with full image
}

-(void) startButtonTouch: (id) sender {
    //set button to be highlighted
    [sender setBackgroundColor: [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
}

#pragma mark invite and change RSVP
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
        
        [[ParseDataStore sharedStore] inviteFriendsToEvent:_eventDetails[@"id"] withFriends:usersToInvite completion:nil];
        
    }];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kActionSheetCancelButtonIndex) {
        return;
    }
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.rsvpStatusButton setTitle:nil forState:UIControlStateNormal];
    [self.rsvpStatusButton addSubview:spinner];
    [self.rsvpStatusButton addConstraint:[NSLayoutConstraint constraintWithItem:spinner
                                                                      attribute:NSLayoutAttributeCenterX
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.rsvpStatusButton
                                                                      attribute:NSLayoutAttributeCenterX
                                                                     multiplier:1.0
                                                                       constant:0.0]];
    [self.rsvpStatusButton addConstraint:[NSLayoutConstraint constraintWithItem:spinner
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.rsvpStatusButton
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1.0
                                                                       constant:0.0]];
    [spinner startAnimating];
    
    NSString *actionTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    [[ParseDataStore sharedStore] changeRSVPStatusToEvent:self.eventDetails[@"id"]
                                                oldStatus:self.eventDetails[@"rsvp_status"]
                                                newStatus:[self eventParameterStringFromStatusString:actionTitle]
                                               completion:^{
        
        self.eventDetails[@"rsvp_status"] = [self eventParameterStringFromStatusString:actionTitle];
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        [self.rsvpStatusButton setTitle:actionTitle forState:UIControlStateNormal];
        
    }];
    
}



- (void)changeRsvpStatus:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    
    if (![self isHost]) {
        
        UIActionSheet *statusSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Going",@"Maybe",@"Not Going", nil];
        [statusSheet showInView:[self view]];
        
    }
}


- (void)resetButtonBackGroundColor:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
}

#pragma mark MapView

- (UITabBarController *)tabBarControllerForMapView
{
    _tabBarController = [[UITabBarController alloc] init];
    
    _statsViewController = [[ActiveEventsStatsViewController alloc] initWithGuestArray:self.eventDetails[@"attending"][@"data"]
                                                                               eventId:self.eventDetails[@"id"]
                                                                         venueLocation:_venueLocation];
    _statsViewController.title = @"Stats";
    
    _mapViewController = [[ActiveEventMapViewController alloc] initWithGuestArray:self.eventDetails[@"attending"][@"data"]
                                                                          eventId:self.eventDetails[@"id"]
                                                                    venueLocation:_venueLocation];
    _mapViewController.title = @"Map";
    
    self.navigationController.title = self.tabBarItem.title;
    [_tabBarController setViewControllers:@[_mapViewController, _statsViewController]];
    
    return _tabBarController;
}

- (void)loadMapView:(id)sender
{
    _tabBarController = [self tabBarControllerForMapView];
    [[self navigationController] pushViewController:_tabBarController animated:YES];
}

#pragma mark Push and Load Active Map

- (void)promptGuestsForTracking: (id) sender {
    
    [self loadMapView:nil];
    [_startTrackingButton removeFromSuperview];
    [self addStopTrackingButtonAndViewMapButton];
    
    [[ParseDataStore sharedStore] setTrackingStatus:YES event:self.eventDetails[@"id"]];
    [[ParseDataStore sharedStore] pushNotificationToGuestOfEvent:_eventDetails[@"id"] completion:nil];
    
}

#pragma mark Map Zoom

-(void)updateMapZoomLocation: (CLLocationCoordinate2D) location {
    [_mapView setRegion:MKCoordinateRegionMakeWithDistance(location, 400, 400) animated:NO];
}



#pragma mark Contraint Methods

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
    if([eventTitle length] != 0){
    CGFloat fontSize = MIN(24,625/[eventTitle length]);
    UIFont *textFont = [UIFont fontWithName:@"Helvetica Neue" size:fontSize];
    
    [_titleLabel setTextColor:[UIColor whiteColor]];
    [_titleLabel setFont:textFont];
    }
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
    [_buttonHolder addSubview:inviteButton];
    [_viewsDictionary addEntriesFromDictionary:@{ @"inviteButton":inviteButton }];
    
    
    [_buttonHolder addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|[inviteButton]|"
                                   options:0
                                   metrics:0
                                   views:_viewsDictionary]];
    
    if ([self isHost])
    {
        
        [_buttonHolder addConstraints:[NSLayoutConstraint
                                       constraintsWithVisualFormat:@"H:|[inviteButton]|"
                                       options:0
                                       metrics:0
                                       views:_viewsDictionary]];

    } else if (![self isHost]) {
        
        _rsvpStatusButton = [[UIButton alloc] init];
        [_rsvpStatusButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        _rsvpStatusButton.showsTouchWhenHighlighted = YES;
        [_rsvpStatusButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
        [_rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
        [_rsvpStatusButton addTarget:self action:@selector(startButtonTouch:) forControlEvents:UIControlEventTouchDown];
        [_rsvpStatusButton addTarget:self action:@selector(changeRsvpStatus:) forControlEvents:UIControlEventTouchUpInside];
        [_rsvpStatusButton addTarget:self action:@selector(resetButtonBackGroundColor:)
                    forControlEvents:UIControlEventTouchUpOutside];
        
        [_rsvpStatusButton setTitle:[self statusStringFromEventParameterString:self.eventDetails[@"rsvp_status"]]
                           forState:UIControlStateNormal];
        
        [_rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
        
        [_buttonHolder addSubview:_rsvpStatusButton];
        [_viewsDictionary addEntriesFromDictionary:@{ @"rsvpStatusButton":_rsvpStatusButton }];
        
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
    }
    
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
    
    
    [_dimensionsDict
     addEntriesFromDictionary:@{ @"screenWidthWithMargin":[NSNumber numberWithFloat:
                                                           ([UIScreen mainScreen].bounds.size.width -
                                                            (TableViewSideMargin * 2))],
                                 
                                 @"sideMargin":[NSNumber numberWithFloat:TableViewSideMargin] }];
    
    //initializing mapView and setting coordinates of location
    _mapView = [[MKMapView alloc]
               initWithFrame:CGRectMake(0, 0, [_dimensionsDict[@"screenWidthWithMargin"] floatValue], 100)];
    [_mapView setMapType:MKMapTypeStandard];
    [_mapView setScrollEnabled:NO];
    [_mapView setZoomEnabled:NO];
    [_mapView setUserInteractionEnabled:YES];
    
    
    _singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(clickedOnMap:)];
    
    [_singleFingerTap setNumberOfTouchesRequired:1];
    NSLog(@"Wrapper size and stuff: %@", NSStringFromCGRect(_wrapper.frame));
    
    [_mapView addGestureRecognizer:_singleFingerTap];
    //[_wrapper addGestureRecognizer:_singleFingerTap];
    NSLog(@"transparent view: %@", NSStringFromCGRect(_transparentView.frame));
    
    NSDictionary *venueDict = _eventDetails[@"venue"];
    NSString *locationName = _eventDetails[@"location"];
    if (venueDict[@"latitude"]) {
        
        NSString *latString = venueDict[@"latitude"];
        NSString *lngString = venueDict[@"longitude"];
        double latitude = [latString doubleValue];
        double longitude = [lngString doubleValue];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        _venueLocation = coordinate;
        
        [self updateMapZoomLocation:_venueLocation];
        
        MKPointAnnotation *annot = [[MKPointAnnotation alloc]init];
        annot.coordinate = _venueLocation;
        [_mapView addAnnotation:annot];
        
        
    } else {
        
        MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
        
        [geocoder fetchGeocodeAddress:locationName completion:^(NSDictionary *geocode, NSError *error) {
            CLLocationCoordinate2D coordinate = [((CLLocation *)geocode[@"location"]) coordinate];
            _venueLocation = coordinate;
            [self updateMapZoomLocation:_venueLocation];
            
            MKPointAnnotation *annot = [[MKPointAnnotation alloc]init];
            annot.coordinate = _venueLocation;
            
            [_mapView addAnnotation:annot];
            
        }];
        
    }
    
    // initializing data source for table view
    _dataSource = [[FBEventDetailsTableDataSource alloc] initWithEventDetails:_eventDetails];
    _detailsTableDelegate = [[FBEventDetailsTableDelegate alloc] init];
    
    //creating table view with event details and setting data source
    _detailsTable = [[UITableView alloc] init];
    [_detailsTable setBackgroundColor:[UIColor whiteColor]];
    [_detailsTable setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_detailsTable setDataSource:_dataSource];
    [_detailsTable setDelegate:_detailsTableDelegate];

    [_detailsTable setTableHeaderView:_wrapper];
    
    //setting some UI aspects of tableview
    [_detailsTable setTableHeaderView:_mapView];
    [_detailsTable.layer setCornerRadius:3];
    [_detailsTable.layer setBorderWidth:0.5];
    [_detailsTable.layer setBorderColor: [[UIColor colorWithWhite:0 alpha:0.3] CGColor]];
    [_detailsTable setUserInteractionEnabled:YES];
    [_detailsTable setScrollEnabled:NO];
    
    [_scrollView addSubview:_detailsTable];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_detailsTable":_detailsTable }];
    
    [_dimensionsDict addEntriesFromDictionary:@{ @"detailsTableContentHeight":[NSNumber numberWithFloat:[_detailsTable contentSize].height] }];

    if (self.isTracking) {
        
        [self addStopTrackingButtonAndViewMapButton];
        
    } else if (self.isHost) {
        
        [self addStartTrackingButton];

        
    } else {
    
        [_scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"V:[_buttonHolder]-(sideMargin)-[_detailsTable(detailsTableContentHeight)]-|"
                                     options:0
                                     metrics:_dimensionsDict
                                     views:_viewsDictionary]];
        
    }
    
    [_scrollView addConstraints:[NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|-(sideMargin)-[_detailsTable(screenWidthWithMargin)]-(sideMargin)-|"
                                 options:0
                                 metrics:_dimensionsDict
                                 views:_viewsDictionary]];
    
}

- (void)addStartTrackingButton{
    
    _startTrackingButton = [[UIButton alloc] init];
    
    UIImage *buttonBaseImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                                 pathForResource:@"tracking-button@2x"
                                                                 ofType:@"png"]];
    UIImage *buttonImage = [buttonBaseImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
    UIImage *buttonPressedBaseImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                                        pathForResource:@"tracking-button-pressed@2x"
                                                                        ofType:@"png"]];
    UIImage *buttonPressedImage = [buttonPressedBaseImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
    
    [_dimensionsDict addEntriesFromDictionary:
     @{ @"trackingButtonImageHeight":[NSNumber numberWithFloat:buttonBaseImage.size.height] }];
    
    [ _startTrackingButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [_startTrackingButton setBackgroundImage:buttonPressedImage forState:UIControlStateSelected];
    [_startTrackingButton setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    
    [_startTrackingButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_startTrackingButton setTitle:@"Start Tracking" forState:UIControlStateNormal];
    [_startTrackingButton setTintColor:[UIColor blackColor]];
    [[_startTrackingButton titleLabel] setFont:[UIFont boldSystemFontOfSize:TrackingButtonFontSize]];
    
    [_startTrackingButton addTarget:self
                             action:@selector(promptGuestsForTracking:)
                   forControlEvents:UIControlEventTouchUpInside];
    
    [_scrollView addSubview:_startTrackingButton];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_startTrackingButton":_startTrackingButton }];
    
    if(_verticalLayoutContraints){
        [_scrollView removeConstraints:_verticalLayoutContraints];
    }
    
    _layoutConstraint =  @"V:[_buttonHolder]-[_startTrackingButton(trackingButtonImageHeight)]-[_detailsTable(detailsTableContentHeight)]-|";
    _verticalLayoutContraints = [NSLayoutConstraint constraintsWithVisualFormat:_layoutConstraint options:0 metrics:_dimensionsDict views:_viewsDictionary];
    
    [_scrollView addConstraints:_verticalLayoutContraints];
    [_scrollView addConstraints:[NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|-(sideMargin)-[_startTrackingButton(screenWidthWithMargin)]-(sideMargin)-|"
                                 options:0
                                 metrics:_dimensionsDict
                                 views:_viewsDictionary]];
    
}

-(void)addStopTrackingButtonAndViewMapButton{
    
    _viewMapButton = [[UIButton alloc]init];
    
    UIImage *viewMapButtonBaseImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                                        pathForResource:@"silver-button-normal@2x"
                                                                        ofType:@"png"]];
    UIImage *viewMapButtonImage = [viewMapButtonBaseImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
    UIImage *viewMapButtonPressedBaseImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                                               pathForResource:@"silver-button-pressed@2x"
                                                                               ofType:@"png"]];
    UIImage *viewMapButtonPressedImage = [viewMapButtonPressedBaseImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
    
    
    [_dimensionsDict addEntriesFromDictionary:
     @{ @"viewMapButtonImageHeight":[NSNumber numberWithFloat:viewMapButtonBaseImage.size.height] }];
    
    
    [_viewMapButton setBackgroundImage:viewMapButtonImage forState:UIControlStateNormal];
    [_viewMapButton setBackgroundImage:viewMapButtonPressedImage forState:UIControlStateSelected];
    [_viewMapButton setBackgroundImage:viewMapButtonPressedImage forState:UIControlStateHighlighted];
    
    [_viewMapButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_viewMapButton setTitle:@"View Map" forState:UIControlStateNormal];
    [_viewMapButton setTintColor:[UIColor blackColor]];
    [[_viewMapButton titleLabel] setFont:[UIFont boldSystemFontOfSize:TrackingButtonFontSize]];
    
    [_viewMapButton addTarget:self
                       action:@selector(loadMapView:)
             forControlEvents:UIControlEventTouchUpInside];
    
    [_scrollView addSubview:_viewMapButton];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_viewMapButton":_viewMapButton }];
    
    
    _stopTrackingButton = [[UIButton alloc] init];
    
    UIImage *buttonBaseImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                                 pathForResource:@"cancel-button-normal@2x"
                                                                 ofType:@"png"]];
    UIImage *buttonImage = [buttonBaseImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
    UIImage *buttonPressedBaseImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                                        pathForResource:@"cancel-button-pressed@2x"
                                                                        ofType:@"png"]];
    UIImage *buttonPressedImage = [buttonPressedBaseImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
    
    
    [_dimensionsDict addEntriesFromDictionary:
     @{ @"trackingButtonImageHeight":[NSNumber numberWithFloat:buttonBaseImage.size.height] }];
    
    
    [ _stopTrackingButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [_stopTrackingButton setBackgroundImage:buttonPressedImage forState:UIControlStateSelected];
    [_stopTrackingButton setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    
    [_stopTrackingButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_stopTrackingButton setTitle:@"Stop Tracking" forState:UIControlStateNormal];
    [_stopTrackingButton setTintColor:[UIColor blackColor]];
    [[_stopTrackingButton titleLabel] setFont:[UIFont boldSystemFontOfSize:TrackingButtonFontSize]];
    
    [_stopTrackingButton addTarget:self
                            action:@selector(doSomething:)
                  forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:_stopTrackingButton];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_stopTrackingButton":_stopTrackingButton }];

    
    if(_verticalLayoutContraints){
        [_scrollView removeConstraints:_verticalLayoutContraints];
    }
    
    _layoutConstraint = @"V:[_buttonHolder]-[_viewMapButton(viewMapButtonImageHeight)]-[_detailsTable(detailsTableContentHeight)]-[_stopTrackingButton(trackingButtonImageHeight)]-|";
    self.verticalLayoutContraints = [NSLayoutConstraint constraintsWithVisualFormat:_layoutConstraint
                                                                            options:0
                                                                            metrics:self.dimensionsDict
                                                                              views:self.viewsDictionary];
    [_scrollView addConstraints:self.verticalLayoutContraints];
    [_scrollView addConstraints:[NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|-(sideMargin)-[_viewMapButton(screenWidthWithMargin)]-(sideMargin)-|"
                                 options:0
                                 metrics:_dimensionsDict
                                 views:_viewsDictionary]];
    [_scrollView addConstraints:[NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|-(sideMargin)-[_stopTrackingButton(screenWidthWithMargin)]-(sideMargin)-|"
                                 options:0
                                 metrics:_dimensionsDict
                                 views:_viewsDictionary]];

}



- (NSString *)statusStringFromEventParameterString:(NSString *)statusParameter
{
    NSString *statusString;
    if ([statusParameter isEqualToString:@"unsure"]) {
        statusParameter = kMaybeEventsKey;
    }
    
    if ([statusParameter isEqualToString:kAttendingEventsKey]) {
        
        statusString = @"Going";
        
    } else if ([statusParameter isEqualToString:kMaybeEventsKey]) {
        
        statusString = @"Maybe";
        
    } else if ([statusParameter isEqualToString:kMaybeEventsKey]) {
        
        statusString = @"Not Going";
        
    } else if ([statusParameter isEqualToString:kNoReplyEventsKey]) {
        
        statusString = @"No Reply";
        
    }
    
    return statusString;
}

- (NSString *)eventParameterStringFromStatusString:(NSString *)eventParameter
{
    NSString *parameterString;
    
    if ([eventParameter isEqualToString:@"Going"]) {
        
        parameterString = kAttendingEventsKey;
        
    } else if ([eventParameter isEqualToString:@"Maybe"]) {
        
        parameterString = kMaybeEventsKey;
        
    } else if ([eventParameter isEqualToString:@"Not Going"]) {
        
        parameterString = kDeclinedEventsKey;
        
    } else if ([eventParameter isEqualToString:@"No Reply"]) {
        
        parameterString = kNoReplyEventsKey;
        
    } else if ([eventParameter isEqualToString:@"No Reply"]) {
        
        parameterString = @"not_replied";
        
    }
    
    return parameterString;
}



- (void)doSomething:(id)sender {
    
    [[ParseDataStore sharedStore] setTrackingStatus:NO event:self.eventDetails[@"id"]];
    [PFCloud callFunctionInBackground:@"deleteEventData" withParameters:@{@"eventId": _eventDetails[@"id"]} block:^(id object, NSError *error) {
        if (error) {
            NSLog(@"deleting in cloud failed");
        }
    }];
    [self.viewMapButton removeFromSuperview];
    [self.stopTrackingButton removeFromSuperview];
    [self addStartTrackingButton];
    
}

- (void)clickedOnMap:(UITapGestureRecognizer *)recognizer
{
    MKMapView *plainMap = [[MKMapView alloc] init];
    [plainMap setRegion:MKCoordinateRegionMakeWithDistance(_venueLocation, 200, 200) animated:NO];
    
    MKPointAnnotation *annot = [[MKPointAnnotation alloc] init];
    annot.coordinate = _venueLocation;
    [plainMap addAnnotation:annot];
    
    UIViewController *mapViewController = [[UIViewController alloc]init];
    mapViewController.view = plainMap;
    [[self navigationController] pushViewController:mapViewController animated:YES];
}

@end
