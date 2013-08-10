
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

static const float TrackingButtonFontSize = 20.0;
static const float TableViewSideMargin = 12.0;
static const float kLatitudeAdjustment = 0.0008;
static const float kLongitudeAsjustment = 0;

@interface FBEventDetailsViewController () <UITextFieldDelegate, UIAlertViewDelegate>
{
    CLLocationCoordinate2D _venueLocation;
    UITabBarController *_tabBarController;
    UIScrollView *_scrollView;
    UIImageView *_coverImageView;
    UILabel *_titleLabel;
    UIView *_buttonHolder;
    UIButton *_rsvpStatusButton;
    UITableView *_detailsTable;
    
    FBEventDetailsTableDataSource *_dataSource;
    __strong MKMapView *_mapView;
    NSString *_newStatus;
    
    __strong FBEventStatusTableController *_statusTableController;
    

    UITabBarItem *_item;
    UIImage *_briefcase;

}

@property (nonatomic, getter = isHost) BOOL host;
@property (nonatomic, getter = hasReplied) BOOL replied;

@property (nonatomic, strong) NSMutableDictionary *eventDetails;

@property (nonatomic, strong) NSMutableDictionary *dimensionsDict;
@property (nonatomic, strong) NSMutableDictionary *viewsDictionary;
@property (nonatomic, strong) UIButton *startTrackingButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic, strong) FBEventDetailsTableDelegate *detailsTableDelegate;

- (void)loadMapView:(id)sender;

- (void)changeRsvpStatus:(id)sender;

@end

@implementation FBEventDetailsViewController

- (id)initWithPartialDetails:(NSDictionary *)partialDetails isHost:(BOOL)isHost hasReplied:(BOOL)hasReplied
{
    self = [super init];
    if (self) {
        _host = isHost;
        _replied = hasReplied;
        _eventDetails = [[NSMutableDictionary alloc] initWithDictionary:partialDetails];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [self setViewPartialEventDetails];
    
    [[ParseDataStore sharedStore] fetchEventDetailsWithEvent:_eventDetails[@"id"] completion:^(NSDictionary *eventDetails) {
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

    if ([self isHost])
    {
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
        
        [_buttonHolder addConstraints:[NSLayoutConstraint
                                       constraintsWithVisualFormat:@"H:|[inviteButton]|"
                                       options:0
                                       metrics:0
                                       views:_viewsDictionary]];

//
//        [_buttonHolder addConstraints:[NSLayoutConstraint
//                                       constraintsWithVisualFormat:@"V: |-[inviteButton]-|"
//                                       options:0
//                                       metrics:0
//                                       views:_viewsDictionary]];
    }

    
    else if (![self isHost])
    {
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
        _rsvpStatusButton = [[UIButton alloc] init];
        [_rsvpStatusButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        _rsvpStatusButton.showsTouchWhenHighlighted = YES;
        [_rsvpStatusButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
        [_rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
        [_rsvpStatusButton addTarget:self action:@selector(startButtonTouch:) forControlEvents:UIControlEventTouchDown];
        [_rsvpStatusButton addTarget:self action:@selector(changeRsvpStatus:) forControlEvents:UIControlEventTouchUpInside];
        [_rsvpStatusButton addTarget:self action:@selector(resetButtonBackGroundColor:)
                    forControlEvents:UIControlEventTouchUpOutside];
        [_rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    
    
        if ([_eventDetails[@"rsvp_status"] isEqualToString:@"attending"])
        {
            _newStatus = @"Going";
        } else if ([_eventDetails[@"rsvp_status"] isEqualToString:@"unsure"])
        {
            _newStatus = @"Maybe";
        } else if ([_eventDetails[@"rsvp_status"] isEqualToString:@"declined"])
        {
            _newStatus = @"Not Going";
        }
        
        [_rsvpStatusButton setTitle:_newStatus forState:UIControlStateNormal];
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
    
    //initializing mapView and setting coordinates of location
    _mapView = [[MKMapView alloc]
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
       [_mapView setMapType:MKMapTypeStandard];
        //[_mapView setCenterCoordinate:_venueLocation animated:NO];
        MKPointAnnotation *annot = [[MKPointAnnotation alloc]init];
        annot.coordinate = _venueLocation;
        [self updateMapZoomLocation:_venueLocation];
        [_mapView addAnnotation:annot];
        
    } else {
        
        MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
        
        [geocoder fetchGeocodeAddress:locationName completion:^(NSDictionary *geocode, NSError *error) {
            CLLocationCoordinate2D coordinate = [((CLLocation *)geocode[@"location"]) coordinate];
            _venueLocation = coordinate;
           // [_mapView setCenterCoordinate:_venueLocation];
            MKPointAnnotation *annot = [[MKPointAnnotation alloc]init];
            annot.coordinate = _venueLocation;
            [self updateMapZoomLocation:_venueLocation];

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
    [_detailsTable setTableHeaderView:_mapView];
    
    //setting some UI aspects of tableview
    [_detailsTable.layer setCornerRadius:3];
    [_detailsTable.layer setBorderWidth:0.5];
    [_detailsTable.layer setBorderColor: [[UIColor colorWithWhite:0 alpha:0.3] CGColor]];
    [_detailsTable setUserInteractionEnabled:NO];
    [_detailsTable setScrollEnabled:NO];
    
    [_dimensionsDict
     addEntriesFromDictionary:@{ @"screenWidthWithMargin":[NSNumber numberWithFloat:
                                                           ([UIScreen mainScreen].bounds.size.width -
                                                                (TableViewSideMargin * 2))],
                                 
                                 @"sideMargin":[NSNumber numberWithFloat:TableViewSideMargin],
                                 
                                 @"detailsTableContentHeight":[NSNumber numberWithFloat:
                                                               [_detailsTable contentSize].height] }];
    

    
    [_scrollView addSubview:_detailsTable];
    [_viewsDictionary addEntriesFromDictionary:@{ @"_detailsTable":_detailsTable }];
    
    if ([self isHost]) {
        
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
        
        [_startTrackingButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [_startTrackingButton setBackgroundImage:buttonPressedImage forState:UIControlStateSelected];
        [_startTrackingButton setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
        
        [_startTrackingButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_startTrackingButton setTitle:@"Start Tracking" forState:UIControlStateNormal];
        [[_startTrackingButton titleLabel] setFont:[UIFont boldSystemFontOfSize:TrackingButtonFontSize]];
        
        [_startTrackingButton addTarget:self
                                 action:@selector(promptGuestsForTracking:)
                       forControlEvents:UIControlEventTouchUpInside];
        
        [_scrollView addSubview:_startTrackingButton];
        [_viewsDictionary addEntriesFromDictionary:@{ @"_startTrackingButton":_startTrackingButton }];
        
        NSString *verticalLayout =
            @"V:[_buttonHolder]-[_startTrackingButton(trackingButtonImageHeight)]-[_detailsTable(detailsTableContentHeight)]-|";
        [_scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:verticalLayout
                                     options:0
                                     metrics:_dimensionsDict
                                     views:_viewsDictionary]];
        [_scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:|-(sideMargin)-[_startTrackingButton(screenWidthWithMargin)]-(sideMargin)-|"
                                     options:0
                                     metrics:_dimensionsDict
                                     views:_viewsDictionary]];
        
    }
    else {
        
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

//- (void)viewDidAppear:(BOOL)animated {
//    
//    [super viewDidAppear:animated];
//    
//    if (!(_eventDetails[@"location"]||_eventDetails[@"venue"][@"lattitude"])) {
//        __strong UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your Event Location Was Invalid" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Submit", nil];
//        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
//        [alert setDelegate:self];
//        UITextField *locationInputTextView = [alert textFieldAtIndex:0];
//        [locationInputTextView setPlaceholder:@"Please Enter a Location"];
//        [alert show];
//    }
//    
//}

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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *locationString = [alertView textFieldAtIndex:0].text;
    MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
    
    [geocoder fetchGeocodeAddress:locationString completion:^(NSDictionary *geocode, NSError *error) {
        CLLocationCoordinate2D coordinate = [((CLLocation *)geocode[@"location"]) coordinate];
        _venueLocation = coordinate;
        if (!coordinate.latitude) {
            [alertView show];
           // [_mapView setCenterCoordinate:_venueLocation];
            MKPointAnnotation *annot = [[MKPointAnnotation alloc]init];
            annot.coordinate = _venueLocation;
            [self updateMapZoomLocation:_venueLocation];

            [_mapView addAnnotation:annot];


        }
        else {
            [_eventDetails setValue:locationString forKey:@"location"];
            [_dataSource updateObject:locationString forKey:@"location"];
            [_detailsTable reloadData];
            //[_mapView setCenterCoordinate:_venueLocation];
            MKPointAnnotation *annot = [[MKPointAnnotation alloc]init];
            annot.coordinate = _venueLocation;
            [self updateMapZoomLocation:_venueLocation];

            [_mapView addAnnotation:annot];
            

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
        
        [[ParseDataStore sharedStore] inviteFriendsToEvent:_eventDetails[@"id"] withFriends:usersToInvite completion:nil];
        
    }];
    
}

- (void)changeRsvpStatus:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    if (![self isHost])
    {
        UIActionSheet *statusSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Going",@"Maybe",@"Not Going", nil];
        [statusSheet showInView:[self view]];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *actionTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([actionTitle isEqualToString:@"Going"])
    {
        _newStatus = @"Going";
    }
    else if ([actionTitle isEqualToString:@"Maybe"])
    {
        _newStatus = @"Maybe";
    }
    else if ([actionTitle isEqualToString:@"Not Going"])
    {
        _newStatus = @"Not Going";
    }
    else{
        return;
    }
    [_rsvpStatusButton setTitle:_newStatus forState:UIControlStateNormal];
    [[ParseDataStore sharedStore] changeRSVPStatusToEvent:_eventDetails[@"id"] newStatus:_newStatus completion:nil];

    
}

- (void) resetButtonBackGroundColor: (id) sender {
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
}

- (void)loadMapView:(id)sender
{
    UIViewController *statsController = [[UIViewController alloc]init];
    statsController.view=[[UIView alloc]init];
    
    _item= [statsController tabBarItem];
    _briefcase= [UIImage imageNamed:@"listFinal.png"];
    [_item setImage:_briefcase];
    
    _tabBarController=[[UITabBarController alloc]init];
    ActiveEventMapViewController *mapViewController = [[ActiveEventMapViewController alloc]
                                                       initWithGuestArray:_eventDetails[@"attending"][@"data"] eventId:_eventDetails[@"id"] venueLocation:_venueLocation];
    [statsController setTitle:@"Stats"];
    [mapViewController setTitle:@"Map"];
    
    [_tabBarController setViewControllers:@[mapViewController, statsController]];
    UIBarButtonItem *backToDetailsButton = [[UIBarButtonItem alloc] initWithTitle:@"Details"
                                                                            style:UIBarButtonItemStyleBordered
                                                                           target:nil
                                                                           action:nil];
    [self.navigationItem setBackBarButtonItem:backToDetailsButton];
    [[self navigationController] pushViewController:_tabBarController animated:YES];
}

-(void) promptGuestsForTracking: (id) sender {
    [self loadMapView:nil];
    [[ParseDataStore sharedStore] notifyUsersWithCompletion:_eventDetails[@"id"] guestArray:_eventDetails[@"attending"][@"data"] completion:nil];
}

-(void)updateMapZoomLocation: (CLLocationCoordinate2D) location{
    MKCoordinateRegion region;
    region.center.latitude = location.latitude;
    region.center.longitude = location.longitude;
    region.span.latitudeDelta = 0.007;
    region.span.longitudeDelta = 0.007;
    [_mapView setRegion:region animated:NO];
    
    
}

@end
