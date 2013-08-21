
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
#import "Toast+UIView.h"
#import "ActiveEventController.h"
#import "CreateEventController.h"

static const float kButtonFontSize = 20.0;
static const float TableViewSideMargin = 12.0;
static const float kLatitudeAdjustment = 0.0008;
static const float kLongitudeAsjustment = 0;
static const BOOL kAllowTrackingForNonActiveEvents = YES;

static NSInteger const kChangeStatusCancelButtonIndex = 3;
static NSInteger const kEditEventCancelButtonIndex = 2;

@interface FBEventDetailsViewController () <UITextFieldDelegate, UIAlertViewDelegate, MKMapViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *eventDetails;
@property (nonatomic) CLLocationCoordinate2D venueLocation;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIImageView *coverImageView;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UIView *buttonHolder;
@property (nonatomic, weak) UIButton *rsvpStatusButton;
@property (nonatomic, weak) UIButton *editEventButton;
@property (nonatomic, weak) MKMapView *mapView;

@property (nonatomic, strong) NSString *status;

@property (nonatomic, weak) UITableView *detailsTable;
@property (nonatomic, strong) FBEventDetailsTableDataSource *dataSource;
@property (nonatomic, strong) FBEventDetailsTableDelegate *detailsTableDelegate;

@property (nonatomic, weak) UIButton *startTrackingButton;
@property (nonatomic, weak) UIButton *stopTrackingButton;
@property (nonatomic, weak) UIButton *viewMapButton;
@property (nonatomic, weak) UISegmentedControl *segmentedControl;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;
@property (nonatomic, weak) UILabel *viewMapLabel;

@property (nonatomic, strong) NSMutableDictionary *dimensionsDict;
@property (nonatomic, strong) NSMutableDictionary *viewsDictionary;
@property (nonatomic, strong) NSArray *verticalLayoutContraints;

@property (nonatomic, strong) UITapGestureRecognizer *singleFingerTap;

@property (nonatomic, getter = isTracking) BOOL tracking;
@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic, getter = isHost) BOOL host;
@property (nonatomic, getter = hasReplied) BOOL replied;

@property (nonatomic, strong) ActiveEventController *activeEventController;

- (void)loadMapView:(id)sender;
- (void)changeRsvpStatus:(id)sender;
- (void)cancelTracking:(id)sender;

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
        
        [[ParseDataStore sharedStore] fetchEventDetailsForEvent:_eventDetails[@"id"] useCache:YES completion:^(NSDictionary *eventDetails) {
            
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

#pragma mark Invite and Change RSVP

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (actionSheet.tag == 0)
    {
        if (buttonIndex == kChangeStatusCancelButtonIndex) {
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
        
    } else {
        
        if (buttonIndex == kEditEventCancelButtonIndex) {
            return;
        }
        
        NSString *actionTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if ([actionTitle isEqualToString:@"Edit"]) {
            
            CreateEventController *createEventController = [[CreateEventController alloc]
                                                            initWithDetailViewController:self
                                                            eventDetails:_eventDetails];
            
            [self.navigationController
             pushViewController:createEventController.presentableViewController
             animated:YES];
            
        } else if ([actionTitle isEqualToString:@"Delete"]) {
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            [self.editEventButton setTitle:nil forState:UIControlStateNormal];
            [self.editEventButton addSubview:spinner];
            
            [self.editEventButton addConstraint:[NSLayoutConstraint constraintWithItem:spinner
                                                                             attribute:NSLayoutAttributeCenterX
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.editEventButton
                                                                             attribute:NSLayoutAttributeCenterX
                                                                            multiplier:1.0
                                                                              constant:0.0]];
            [self.editEventButton addConstraint:[NSLayoutConstraint constraintWithItem:spinner
                                                                             attribute:NSLayoutAttributeCenterY
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.editEventButton
                                                                             attribute:NSLayoutAttributeCenterY
                                                                            multiplier:1.0
                                                                              constant:0.0]];
            
            [spinner startAnimating];
            
            [[ParseDataStore sharedStore] deleteEvent:_eventDetails[@"id"] completion:^{
                
                UITabBarController *tabBarController = [[EventsListController sharedListController] presentableViewController];
                
                NSInteger selectedInd = [tabBarController selectedIndex];
                NSString *listKey;
        
                if (selectedInd == 0){
                    listKey = kHostEventsKey;
                } else if (selectedInd == 1) {
                    listKey = kHostEventsKey;
                } else if (selectedInd == 2) {
                    listKey = kAttendingEventsKey;
                } else if (selectedInd == 3) {
                    listKey = kMaybeEventsKey;
                }
                
                [[ParseDataStore sharedStore] fetchEventListDataForListKey:listKey completion:^(NSArray *eventsList) {
                    [spinner stopAnimating];
                    [spinner removeFromSuperview];
                    [[EventsListController sharedListController] refreshTableViewForEventsListKey:listKey newEventsList:eventsList endRefreshForRefreshControl:nil];
                    [self.navigationController popToViewController:[[EventsListController sharedListController] presentableViewController] animated:YES];
                }];
            }];
        }
    }
}

- (void)refreshDetailsViewWithCompleteDetails:(NSDictionary *)completeEventDetails
{
    self.eventDetails = [[NSMutableDictionary alloc] initWithDictionary:completeEventDetails];
    [self setViewPartialEventDetails];
    [self setViewCompleteEventDetails];
    [_detailsTable setNeedsDisplay];
}

- (void)changeRsvpStatus:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    
    if (![self isHost]) {
        
        UIActionSheet *rsvpStatusSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Going",@"Maybe",@"Not Going", nil];
        [rsvpStatusSheet setTag:0];
        
        [rsvpStatusSheet showInView:[self view]];
        
    }
}

- (void)resetButtonBackGroundColor:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
}

#pragma mark Map Zoom

- (void)mapView:(MKMapView *)mapView updateMapZoomLocation:(CLLocationCoordinate2D)location
{
    [mapView setRegion:MKCoordinateRegionMakeWithDistance(location, 400, 400) animated:NO];
}

#pragma mark Contraint Methods

- (void)setViewPartialEventDetails
{
    _dimensionsDict = [[NSMutableDictionary alloc]
                       initWithDictionary:@{ @"screenWidth":[NSNumber numberWithFloat:
                                                             [UIScreen mainScreen].bounds.size.width] }];
    
    _viewsDictionary = [[NSMutableDictionary alloc] init];
    
    // Creating new scroll view
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    [scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [scrollView setBackgroundColor:[UIColor whiteColor]];
    [scrollView setDelegate:self];
    
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
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
    UIImageView *coverImageView = [[UIImageView alloc] init];
    [coverImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [_scrollView addSubview:coverImageView];
    self.coverImageView = coverImageView;
    
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
    UILabel *titleLabel = [[UILabel alloc] init];
    [titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setText:eventTitle];
    [titleLabel setUserInteractionEnabled:NO];
    
    UIFont *textFont;
    if ([eventTitle length] != 0) {
        CGFloat fontSize = MIN(24,625/[eventTitle length]);
        textFont = [UIFont fontWithName:@"Helvetica Neue" size:fontSize];
    }
    
    [titleLabel setTextColor:[UIColor whiteColor]];
    if (textFont) {
        [titleLabel setFont:textFont];
    }
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    
    [_coverImageView addSubview:titleLabel];
    self.titleLabel = titleLabel;
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
    
    [_coverImageView setUserInteractionEnabled:YES];
    
    
    UIView *buttonHolder = [[UIView alloc] init];
    [buttonHolder setBackgroundColor:[UIColor whiteColor]];
    [buttonHolder setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [_scrollView addSubview:buttonHolder];
    self.buttonHolder = buttonHolder;
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
    if ([self hasReplied])
    {
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
            UIButton *editEventButton = [[UIButton alloc] init];
            [editEventButton setTranslatesAutoresizingMaskIntoConstraints:NO];
            editEventButton.showsTouchWhenHighlighted = YES;
            [editEventButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
            [editEventButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [editEventButton addTarget:self action:@selector(startButtonTouch:) forControlEvents:UIControlEventTouchDown];
            [editEventButton addTarget:self action:@selector(editCurrentEvent:) forControlEvents:UIControlEventTouchUpInside];
            [editEventButton addTarget:self action:@selector(resetButtonBackGroundColor:)
                   forControlEvents:UIControlEventTouchUpOutside];
            [editEventButton setTitle:@"Edit" forState:UIControlStateNormal];
            [_buttonHolder addSubview:editEventButton];
            self.editEventButton = editEventButton;
            
            [_viewsDictionary addEntriesFromDictionary:@{ @"editEventButton":_editEventButton}];
            
            [_buttonHolder addConstraints:[NSLayoutConstraint
                                           constraintsWithVisualFormat:@"V:|[editEventButton]|"
                                           options:0
                                           metrics:0
                                           views:_viewsDictionary]];
            [_buttonHolder addConstraints:[NSLayoutConstraint
                                           constraintsWithVisualFormat:@"H:|[inviteButton][editEventButton]|"
                                           options:0
                                           metrics:0
                                           views:_viewsDictionary]];
            [_buttonHolder addConstraints:[NSLayoutConstraint
                                           constraintsWithVisualFormat:@"[inviteButton(==editEventButton)]"
                                           options:0
                                           metrics:0
                                           views:_viewsDictionary]];
            
        } else if (![self isHost]) {
            
            UIButton *rsvpStatusButton = [[UIButton alloc] init];
            [rsvpStatusButton setTranslatesAutoresizingMaskIntoConstraints:NO];
            rsvpStatusButton.showsTouchWhenHighlighted = YES;
            [rsvpStatusButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
            [rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
            [rsvpStatusButton addTarget:self action:@selector(startButtonTouch:) forControlEvents:UIControlEventTouchDown];
            [rsvpStatusButton addTarget:self action:@selector(changeRsvpStatus:) forControlEvents:UIControlEventTouchUpInside];
            [rsvpStatusButton addTarget:self action:@selector(resetButtonBackGroundColor:)
                        forControlEvents:UIControlEventTouchUpOutside];
            
            [rsvpStatusButton setTitle:[self statusStringFromEventParameterString:self.eventDetails[@"rsvp_status"]]
                               forState:UIControlStateNormal];
            
            [rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
            
            [_buttonHolder addSubview:rsvpStatusButton];
            self.rsvpStatusButton = rsvpStatusButton;
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
    }
    
    else
    {
        UIButton *rsvpStatusButton = [[UIButton alloc] init];
        [rsvpStatusButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        rsvpStatusButton.showsTouchWhenHighlighted = YES;
        [rsvpStatusButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
        [rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
        [rsvpStatusButton addTarget:self action:@selector(startButtonTouch:) forControlEvents:UIControlEventTouchDown];
        [rsvpStatusButton addTarget:self action:@selector(changeRsvpStatus:) forControlEvents:UIControlEventTouchUpInside];
        [rsvpStatusButton addTarget:self action:@selector(resetButtonBackGroundColor:)
                    forControlEvents:UIControlEventTouchUpOutside];
        
        [rsvpStatusButton setTitle:[self statusStringFromEventParameterString:self.eventDetails[@"rsvp_status"]]
                           forState:UIControlStateNormal];
        
        [rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
        
        [_buttonHolder addSubview:rsvpStatusButton];
        self.rsvpStatusButton = rsvpStatusButton;
        [_viewsDictionary addEntriesFromDictionary:@{ @"rsvpStatusButton":_rsvpStatusButton }];
        
        [_buttonHolder addConstraints:[NSLayoutConstraint
                                       constraintsWithVisualFormat:@"V:|[rsvpStatusButton]|"
                                       options:0
                                       metrics:0
                                       views:_viewsDictionary]];
        [_buttonHolder addConstraints:[NSLayoutConstraint
                                       constraintsWithVisualFormat:@"H:|[rsvpStatusButton]|"
                                       options:0
                                       metrics:0
                                       views:_viewsDictionary]];
    }
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_scrollView addSubview:spinner];
    self.spinner = spinner;
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

#pragma mark  Create New Event
- (IBAction)editCurrentEvent:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    UIActionSheet *editStatusSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Edit",@"Delete", nil];
    [editStatusSheet setTag:1];
    
    if (self.spinner) {
        [self.spinner stopAnimating];
        [self.spinner removeFromSuperview];
    }
    
    [editStatusSheet showInView:[self view]];
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
    MKMapView *mapView = [[MKMapView alloc]
                          initWithFrame:CGRectMake(0, 0, [_dimensionsDict[@"screenWidthWithMargin"] floatValue], 100)];
    [mapView setMapType:MKMapTypeStandard];
    [mapView setScrollEnabled:NO];
    [mapView setZoomEnabled:NO];
    [mapView setUserInteractionEnabled:YES];
    
    _singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(clickedOnMap:)];
    
    [_singleFingerTap setNumberOfTouchesRequired:1];
    
    [mapView addGestureRecognizer:_singleFingerTap];

    NSDictionary *venueDict = _eventDetails[@"venue"];
    NSString *locationName = _eventDetails[@"location"];
    if (venueDict[@"latitude"]) {
        
        NSString *latString = venueDict[@"latitude"];
        NSString *lngString = venueDict[@"longitude"];
        double latitude = [latString doubleValue];
        double longitude = [lngString doubleValue];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        self.venueLocation = coordinate;
        
        PFGeoPoint *venueLocationGeoPoint = [PFGeoPoint geoPointWithLatitude:self.venueLocation.latitude longitude:self.venueLocation.longitude];
        
        [self mapView:mapView updateMapZoomLocation:self.venueLocation];
        
        MKPointAnnotation *annot = [[MKPointAnnotation alloc]init];
        annot.coordinate = _venueLocation;
        [mapView addAnnotation:annot];
        
        
    } else {
        
        MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
        
        [geocoder fetchGeocodeAddress:locationName completion:^(NSDictionary *geocode, NSError *error) {
            if (geocode) {
                CLLocationCoordinate2D coordinate = [((CLLocation *)geocode[@"location"]) coordinate];
                self.venueLocation = coordinate;
                [self mapView:mapView updateMapZoomLocation:self.venueLocation];
                
                MKPointAnnotation *annot = [[MKPointAnnotation alloc]init];
                annot.coordinate = _venueLocation;
                
                [mapView addAnnotation:annot];
                
            }
        }];
        
    }
    
    // initializing data source for table view
    _dataSource = [[FBEventDetailsTableDataSource alloc] initWithEventDetails:_eventDetails];
    _detailsTableDelegate = [[FBEventDetailsTableDelegate alloc] init];
    
    //creating table view with event details and setting data source
    UITableView *detailsTable = [[UITableView alloc] init];
    [detailsTable setBackgroundColor:[UIColor whiteColor]];
    [detailsTable setTranslatesAutoresizingMaskIntoConstraints:NO];
    [detailsTable setDataSource:_dataSource];
    [detailsTable setDelegate:_detailsTableDelegate];
    
    //setting some UI aspects of tableview
    [detailsTable setTableHeaderView:_mapView];
    [detailsTable.layer setCornerRadius:3];
    [detailsTable.layer setBorderWidth:0.5];
    [detailsTable.layer setBorderColor: [[UIColor colorWithWhite:0 alpha:0.3] CGColor]];
    [detailsTable setUserInteractionEnabled:YES];
    [detailsTable setScrollEnabled:NO];
    
    [_scrollView addSubview:detailsTable];
    self.detailsTable = detailsTable;
    
    [detailsTable setTableHeaderView:mapView];
    self.mapView = mapView;
    
    [_viewsDictionary addEntriesFromDictionary:@{ @"_detailsTable":_detailsTable }];
    
    [_dimensionsDict addEntriesFromDictionary:@{ @"detailsTableContentHeight":[NSNumber numberWithFloat:[_detailsTable contentSize].height] }];

    [_scrollView addConstraints:[NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|-(sideMargin)-[_detailsTable(screenWidthWithMargin)]-(sideMargin)-|"
                                 options:0
                                 metrics:_dimensionsDict
                                 views:_viewsDictionary]];
    
    if (self.isTracking) {
        
        if (self.isHost) {
            [self addStopTrackingButtonAndViewMapButton];
        } else {
            [self addViewMapButtonAndSegmentedControlForTrackingSettings];
        }
    } else if (self.isHost && ([self isActive] || kAllowTrackingForNonActiveEvents)) {
        
        [self addStartTrackingButton];

        
    } else {
    
        [_scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"V:[_buttonHolder]-(sideMargin)-[_detailsTable(detailsTableContentHeight)]-|"
                                     options:0
                                     metrics:_dimensionsDict
                                     views:_viewsDictionary]];
        
    }
    
}

- (void)addStartTrackingButton{
    
    if ([self.stopTrackingButton superview]) {
        [self.stopTrackingButton removeFromSuperview];
    }
    
    if ([self.viewMapLabel superview]) {
        [self.viewMapLabel removeFromSuperview];
    }
    
    UIButton *startTrackingButton = [self createStartTrackingButton];
    
    [self.scrollView addSubview:startTrackingButton];
    self.startTrackingButton = startTrackingButton;
    [self.viewsDictionary addEntriesFromDictionary:@{ @"startTrackingButton": self.startTrackingButton }];
    
    if (self.verticalLayoutContraints) {
        [self.scrollView removeConstraints:self.verticalLayoutContraints];
    }
    
    NSString *layoutConstraint = @"V:[_buttonHolder]-[startTrackingButton(startTrackingButtonHeight)]-[_detailsTable(detailsTableContentHeight)]-|";
    self.verticalLayoutContraints = [NSLayoutConstraint
                                     constraintsWithVisualFormat:layoutConstraint
                                     options:0
                                     metrics:self.dimensionsDict
                                     views:self.viewsDictionary];
    
    [self.scrollView addConstraints:self.verticalLayoutContraints];
    [self.scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:|-(sideMargin)-[startTrackingButton(screenWidthWithMargin)]-(sideMargin)-|"
                                     options:0
                                     metrics:self.dimensionsDict
                                     views:self.viewsDictionary]];
    
}

- (void)addStopTrackingButtonAndViewMapButton
{
    if ([self.startTrackingButton superview]) {
        [self.startTrackingButton removeFromSuperview];
    }
    
    UILabel *viewMapLabel = [self createViewMapButton];
    [self.scrollView addSubview:viewMapLabel];
    self.viewMapLabel = viewMapLabel;
    
    [self.viewsDictionary addEntriesFromDictionary:@{ @"_viewMapLabel": self.viewMapLabel }];
    
    
    UIButton *stopTrackingButton = [self createStopTrackingButton];
    [self.scrollView addSubview:stopTrackingButton];
    self.stopTrackingButton = stopTrackingButton;
    [self.viewsDictionary addEntriesFromDictionary:@{ @"stopTrackingButton": self.stopTrackingButton }];
    
    if (self.verticalLayoutContraints) {
        [self.scrollView removeConstraints:self.verticalLayoutContraints];
    }
    
    NSString *layoutConstraint = @"V:[_buttonHolder]-[_viewMapLabel][_detailsTable(detailsTableContentHeight)]-(sideMargin)-[stopTrackingButton(stopTrackingButtonHeight)]-|";
    self.verticalLayoutContraints = [NSLayoutConstraint constraintsWithVisualFormat:layoutConstraint
                                                                            options:0
                                                                            metrics:self.dimensionsDict
                                                                              views:self.viewsDictionary];
    [self.scrollView addConstraints:self.verticalLayoutContraints];
    [self.scrollView addConstraints:[NSLayoutConstraint
                                    constraintsWithVisualFormat:@"H:|-(sideMargin)-[_viewMapLabel(screenWidthWithMargin)]-(sideMargin)-|"
                                     options:0
                                    metrics:self.dimensionsDict
                                    views:self.viewsDictionary]];
    [self.scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:|-(sideMargin)-[stopTrackingButton(screenWidthWithMargin)]-(sideMargin)-|"
                                     options:0
                                     metrics:self.dimensionsDict
                                     views:self.viewsDictionary]];
 
}

- (void)addViewMapButtonAndSegmentedControlForTrackingSettings
{
    
    UILabel *viewMapLabel = [self createViewMapButton];
    
    [self.scrollView addSubview:viewMapLabel];
    self.viewMapLabel = viewMapLabel;
    [self.viewsDictionary addEntriesFromDictionary:@{ @"_viewMapLabel": self.viewMapLabel }];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.scrollView addSubview:spinner];
    
    [self.viewsDictionary addEntriesFromDictionary:@{ @"segmentedControlSpinner": spinner }];
    
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:spinner
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.scrollView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0
                                                                 constant:0.0]];
    
    if (self.verticalLayoutContraints) {
        [self.scrollView removeConstraints:self.verticalLayoutContraints];
    }
    
    NSString *layoutConstraint = @"V:[_buttonHolder]-[_viewMapLabel][_detailsTable(detailsTableContentHeight)]-(20)-[segmentedControlSpinner]-(20)-|";
    self.verticalLayoutContraints = [NSLayoutConstraint constraintsWithVisualFormat:layoutConstraint
                                                                            options:0
                                                                            metrics:self.dimensionsDict
                                                                              views:self.viewsDictionary];
    [self.scrollView addConstraints:self.verticalLayoutContraints];
    [self.scrollView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:|-(sideMargin)-[_viewMapLabel(screenWidthWithMargin)]-(sideMargin)-|"
                                     options:0
                                  metrics:self.dimensionsDict
                                    views:self.viewsDictionary]];
  
    [spinner startAnimating];
    
    [[ParseDataStore sharedStore] fetchPermissionForEvent:self.eventDetails[@"id"] completion:^(NSString *identity) {
        
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]
                                                        initWithItems:@[@"Allow", @"Anon", @"Disallow"]];
        [segmentedControl setTranslatesAutoresizingMaskIntoConstraints:NO];
        [segmentedControl addTarget:self
                             action:@selector(handleSegmentedControl:)
                   forControlEvents:UIControlEventValueChanged];
        
        NSInteger selectedIndex = [self segmentedControlIndexForPermission:identity];
        [segmentedControl setSelectedSegmentIndex:selectedIndex];
        
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        
        [self.scrollView addSubview:segmentedControl];
        self.segmentedControl = segmentedControl;
        
        [self.viewsDictionary addEntriesFromDictionary:@{ @"segmentedControl": self.segmentedControl }];
        [self.dimensionsDict addEntriesFromDictionary:@{ @"segmentedControlHeight": [NSNumber numberWithFloat:40] }];
    
        [self.scrollView removeConstraints:self.verticalLayoutContraints];
        
        NSString *layoutConstraint = @"V:[_buttonHolder]-[_viewMapLabel][_detailsTable(detailsTableContentHeight)]-[segmentedControl(segmentedControlHeight)]-|";
        self.verticalLayoutContraints = [NSLayoutConstraint constraintsWithVisualFormat:layoutConstraint
                                                                                options:0
                                                                                metrics:self.dimensionsDict
                                                                                  views:self.viewsDictionary];
        [self.scrollView addConstraints:self.verticalLayoutContraints];
        [self.scrollView addConstraints:[NSLayoutConstraint
                                         constraintsWithVisualFormat:@"H:|-(sideMargin)-[segmentedControl(screenWidthWithMargin)]-(sideMargin)-|"
                                         options:0
                                         metrics:self.dimensionsDict
                                         views:self.viewsDictionary]];
    }];
    
}

- (UIButton *)createStartTrackingButton
{
    return [self createButtonWithTitle:@"Start Tracking"
                           normalImage:[UIImage imageNamed:@"tracking-button-normal.png"]
                          pressedImage:[UIImage imageNamed:@"tracking-button-pressed.png"]
                              selector:@selector(startTracking:)
                      dimensionDictKey:@"startTrackingButtonHeight"];

}

- (UIButton *)createStopTrackingButton
{
    return [self createButtonWithTitle:@"Stop Tracking"
                           normalImage:[UIImage imageNamed:@"cancel-button-normal.png"]
                          pressedImage:[UIImage imageNamed:@"cancel-button-pressed.png"]
                              selector:@selector(cancelTracking:)
                      dimensionDictKey:@"stopTrackingButtonHeight"];
}

- (UILabel *)createViewMapButton
{
    UILabel *viewMap = [[UILabel alloc] init];
    [viewMap setTranslatesAutoresizingMaskIntoConstraints:NO];
    viewMap.text = @"Event is active. Press map to view.";
    [viewMap setFont:[UIFont systemFontOfSize:12]];
    viewMap.textColor = [UIColor colorWithRed:0 green:128/255.0f blue:0 alpha:1];
    viewMap.textAlignment = NSTextAlignmentCenter;
    return viewMap;
}

- (UIButton *)createButtonWithTitle:(NSString *)title
                        normalImage:(UIImage *)normalImage
                       pressedImage:(UIImage *)pressedImage
                           selector:(SEL)selector
                   dimensionDictKey:(NSString *)dimensionDictKey
{
    UIButton *button = [[UIButton alloc] init];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    UIImage *buttonBaseNormalImage = normalImage;
    UIImage *buttonNormalImage = [buttonBaseNormalImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
    UIImage *buttonBasePressedImage = pressedImage;
    UIImage *buttonPressedImage = [buttonBasePressedImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
    
    [_dimensionsDict addEntriesFromDictionary:
         @{ dimensionDictKey:[NSNumber numberWithFloat:buttonBaseNormalImage.size.height] }];
    
    [button setBackgroundImage:buttonNormalImage forState:UIControlStateNormal];
    [button setBackgroundImage:buttonPressedImage forState:UIControlStateSelected];
    [button setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    
    [button setTitle:title forState:UIControlStateNormal];
    [[button titleLabel] setFont:[UIFont boldSystemFontOfSize:kButtonFontSize]];
    
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    return button;
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

#pragma mark Scroll View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    int yPosition = scrollView.contentOffset.y;
    if (yPosition < 30) {
        scrollView.bounces = NO;
    } else {
        scrollView.bounces = YES;
    }
}

#pragma mark Segmented Control
- (NSInteger)segmentedControlIndexForPermission:(NSString *)permission
{
    if ([permission isEqualToString:allowed]) {
        return 0;
    } else if ([permission isEqualToString:anonymous]) {
        return 1;
    } else if ([permission isEqualToString:notAllowed]) {
        return 2;
    } else {
        return 9;
    }
}

- (void)handleSegmentedControl:(UISegmentedControl *)segmentedControl
{
    void (^completionBlock)() = ^() {
        [self.view hideToastActivity];
    };
    
    [self.view makeToastActivity];
    NSInteger selectedSegmentIndex = segmentedControl.selectedSegmentIndex;
    if (selectedSegmentIndex == 0) {
        [[ParseDataStore sharedStore] changePermissionForEvent:self.eventDetails[@"id"] identity:allowed completion:completionBlock];
    } else if (selectedSegmentIndex == 1) {
        [[ParseDataStore sharedStore] changePermissionForEvent:self.eventDetails[@"id"] identity:anonymous completion:completionBlock];
    } else if (selectedSegmentIndex == 2) {
        [[ParseDataStore sharedStore] changePermissionForEvent:self.eventDetails[@"id"] identity:notAllowed completion:completionBlock];
    }
}

#pragma mark Methods for Buttons Pressed

- (void)cancelTracking:(id)sender {

    if ([self.viewMapLabel superview]) {
        self.viewMapLabel.textColor = [UIColor lightTextColor];
        self.viewMapLabel.text = @"Stopping tracking for guests...";
        [self.viewMapLabel setNeedsDisplay];
    }
    
    __block UIActivityIndicatorView *stopTrackingSpinner;
    if ([self.stopTrackingButton superview]) {
        stopTrackingSpinner = [[UIActivityIndicatorView alloc]
                               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        stopTrackingSpinner.center = self.stopTrackingButton.center;
        [stopTrackingSpinner setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.stopTrackingButton setTitle:nil forState:UIControlStateNormal];
        [self.stopTrackingButton addSubview:stopTrackingSpinner];
        [self.stopTrackingButton addConstraint:[NSLayoutConstraint constraintWithItem:self.stopTrackingButton
                                                                            attribute:NSLayoutAttributeCenterX
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:stopTrackingSpinner
                                                                            attribute:NSLayoutAttributeCenterX
                                                                           multiplier:1.0
                                                                             constant:0.0]];
        [self.stopTrackingButton addConstraint:[NSLayoutConstraint constraintWithItem:self.stopTrackingButton
                                                                            attribute:NSLayoutAttributeCenterY
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:stopTrackingSpinner
                                                                            attribute:NSLayoutAttributeCenterY
                                                                           multiplier:1.0
                                                                             constant:0.0]];
        [stopTrackingSpinner startAnimating];
    }
    
    [[ParseDataStore sharedStore] setTrackingStatus:NO event:self.eventDetails[@"id"] completion:nil];
    [[ParseDataStore sharedStore] pushEventCancelledToGuestsOfEvent:self.eventDetails[@"id"] completion:^{
        [PFCloud callFunctionInBackground:@"deleteEventData" withParameters:@{ @"eventId": self.eventDetails[@"id"] } block:^(id object, NSError *error) {
            
            if (stopTrackingSpinner) {
                [stopTrackingSpinner stopAnimating];
                [stopTrackingSpinner removeFromSuperview];
            }
            
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error deleting event!"
                                                                    message:error.localizedDescription
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                
                if (self.viewMapLabel) {
                    [self.viewMapLabel setText:@"Event is active. Press map to view."];
                }
                if (self.stopTrackingButton) {
                    [self.stopTrackingButton setTitle:@"Stop Tracking" forState:UIControlStateNormal];
                }
                self.tracking = NO;
                //TODO: may break demo
                self.activeEventController = nil;
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:@"Successfully ended tracking for event."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                [self addStartTrackingButton];
            }
            
        }];
    }];
}

- (void)startTracking:(id)sender
{
    [self.scrollView makeToastActivity];
    [[ParseDataStore sharedStore] setTrackingStatus:YES event:self.eventDetails[@"id"] completion:^{
        self.tracking = YES;
        [[ParseDataStore sharedStore] pushNotificationsToGuestsOfEvent:self.eventDetails[@"id"] completion:^(NSArray *friendIdsArray) {
            [self.scrollView hideToastActivity];
            [self loadMapView:nil];
            [self addStopTrackingButtonAndViewMapButton];
        }];
    }];
}

- (void)loadMapView:(id)sender {

    if (!self.activeEventController) {
        self.activeEventController = [[ActiveEventController alloc] initWithEventId:self.eventDetails[@"id"]
                                                                      venueLocation:_venueLocation];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self.activeEventController
                                             selector:@selector(startTimerForUpdates:)
                                                 name:@"UINavigationControllerWillShowViewControllerNotification"
                                               object:self.navigationController];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Details"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];
    
    [self.navigationItem setBackBarButtonItem:backButton];
    
    [self.navigationController pushViewController:[self.activeEventController presentableViewController] animated:YES];
}

- (void)tap:(UIGestureRecognizer*)gr
{
    //push new popover view with full image
}

- (void)startButtonTouch:(id)sender
{
    //set button to be highlighted
    [sender setBackgroundColor: [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
}

- (void)inviteFriends:(id)sender {
    
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

- (void)clickedOnMap:(UITapGestureRecognizer *)recognizer
{

    if ([self isTracking]) {
        [self loadMapView:nil];
    } else {
        MKMapView *plainMap = [[MKMapView alloc] init];
        [plainMap setRegion:MKCoordinateRegionMakeWithDistance(_venueLocation, 400, 400) animated:NO];
        
        MKPointAnnotation *annot = [[MKPointAnnotation alloc] init];
        annot.coordinate = _venueLocation;
        [plainMap addAnnotation:annot];
        
        UIViewController *mapViewController = [[UIViewController alloc]init];
        mapViewController.view = plainMap;
        
        [[self navigationController] pushViewController:mapViewController animated:YES];
    }
}

@end
