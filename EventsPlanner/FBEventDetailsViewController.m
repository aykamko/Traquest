//
//  FBEventDetailsViewController.m
//  EventsPlanner
//
//  Created by Ashwin Murthy on 7/25/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import "FBEventDetailsViewController.h"
#import "MKGeocodingService.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <FacebookSDK/FacebookSDK.h>
#import "FBEventsDetailsDataSource.h"
#import "ActiveEventMapViewController.h"
#import "UIImage+ImageCrop.h"
#import "ParseDataStore.h"
#import "FBEventStatusTableController.h"

@interface FBEventDetailsViewController ()<UITextFieldDelegate, UIAlertViewDelegate>

{
    BOOL _isHost;
   CLLocationCoordinate2D venueLocationCoordinate;
    NSString *_venueLocationString;
    NSDictionary *_eventDetails;
    NSMutableArray *_friendsIDArray;
    __strong ActiveEventMapViewController *_mapViewController;
    
    __strong GMSMapView *_mapView;
    __strong UIView *_mainView;
    UILabel *_titleLabel;
    UIImage *_originalEventImage;
    UIView *_buttonHolder;
    FBEventsDetailsDataSource *_dataSource;
    UITableView *_detailsTable;
    NSMutableArray *_attendingFriends;
    
    __strong FBEventStatusTableController *_statusTableController;
    
    __strong UIButton *_trackingButton;
}

- (void)moveMapCameraAndPlaceMarkerAtCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)loadMapView:(id)sender;

- (void)changeRsvpStatus:(id)sender;

@end

@implementation FBEventDetailsViewController

- (id)initWithEventDetails:(NSDictionary *)details isHost:(BOOL) isHost
{
    self = [super init];
    if (self) {
        _isHost = isHost;
        _eventDetails = details;
        FBGraphObject *fbGraphObj = (FBGraphObject *)_eventDetails;
        
        _dataSource = [[FBEventsDetailsDataSource alloc] initWithEventDetails:[[NSMutableDictionary alloc] initWithDictionary:details]];
        NSArray *attendingFriends = fbGraphObj[@"attending"][@"data"];
        
        
        _venueLocationString= (NSString *)_eventDetails[@"location"];
        
        _friendsIDArray = [[NSMutableArray alloc] init];
        for (NSDictionary *friend in attendingFriends)
        {
            [_friendsIDArray addObject:(NSString *)friend[@"id"]];
            NSLog(@"%@", friend[@"id"]);
        }
        
        
        
        
        [[ParseDataStore sharedStore] initWithFriends:_friendsIDArray];
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!(_eventDetails[@"location"]||_eventDetails[@"venue"][@"lattitude"])) {
        __strong UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your Event Location Was Invalid" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Submit", nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alert setDelegate:self];
        UITextField *locationInputTextView = [alert textFieldAtIndex:0];
        [locationInputTextView setPlaceholder:@"Please Enter a Location"];
        [alert show];
    }
}

- (void)viewDidLoad
{
    
    //initialzing dimension values that are re-used in creating new children
    CGPoint origin = self.view.frame.origin;
    CGSize frameSize = self.view.frame.size;
    CGRect largeRect = {origin,{frameSize.width,frameSize.height}};
    CGRect skeletonRect = CGRectMake(origin.x,origin.y, frameSize.width, 0); //re-used for init -ing direct children of mainView
    CGFloat margin = frameSize.width/20;
    
    //creating new scrollview and setting as skeleton of mainView
    UIScrollView *newScrollView = [[UIScrollView alloc] initWithFrame:largeRect];
    _mainView = [[UIView alloc] initWithFrame:largeRect];
    [newScrollView setContentSize:largeRect.size];
    self.view = newScrollView;
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:_mainView];
    
    //initialzing cover photo
    skeletonRect.size.height = frameSize.width/3; //arbitrary chosen height for cover photo as function of width
    UIImageView *eventImageView = [[UIImageView alloc] initWithFrame:skeletonRect];
    
    //getting image for cover photo
    _originalEventImage = _eventDetails[@"cover"];
    NSLog(@"YO DAQG%f, %f", _originalEventImage.size.width, _originalEventImage.size.height);
    UIImage *scaledImage = [UIImage imageWithImage:_originalEventImage scaledToWidth:eventImageView.frame.size.width];
    NSLog(@"%f, %f", scaledImage.size.width, scaledImage.size.height);

    UIImage *croppedScaledImage = [UIImage imageWithImage:scaledImage cropRectFromCenterOfSize:eventImageView.frame.size];
    NSLog(@"%f, %f", croppedScaledImage.size.width, croppedScaledImage.size.height);

    eventImageView.image = croppedScaledImage;
    
    //adding image to mainView and adding gesture recognizer
    [eventImageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *eventImageRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [eventImageRecognizer setNumberOfTapsRequired:1];
    [eventImageView addGestureRecognizer:eventImageRecognizer];
    
    [_mainView addSubview:eventImageView];

    //resizing skeletonRect
    skeletonRect.origin.y += skeletonRect.size.height;
    skeletonRect.size.height = frameSize.width/8;
    
    //initializing buttonHolder
    _buttonHolder = [[UIView alloc] initWithFrame:skeletonRect];
    [_mainView addSubview:_buttonHolder];
    CGRect buttonSkeletonRect = {{0,0},{frameSize.width/2,frameSize.width/8}};
    skeletonRect.origin.y += skeletonRect.size.height + margin;
    
    //creating Invite Friends Button features
    UIButton *inviteButton = [[UIButton alloc] initWithFrame:buttonSkeletonRect];
    inviteButton.showsTouchWhenHighlighted = YES;
    [inviteButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    [inviteButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [inviteButton addTarget:self action:@selector(startButtonTouch:) forControlEvents:UIControlEventTouchDown];
    [inviteButton addTarget:self action:@selector(inviteFriends:) forControlEvents:UIControlEventTouchUpInside];
    [inviteButton addTarget:self action:@selector(resetButtonBackGroundColor:) forControlEvents:UIControlEventTouchUpOutside];
    [inviteButton setTitle:@"Invite" forState:UIControlStateNormal];
    
    //creating RSVP Status button, need to figure out if writing from FB SDK is possible
    buttonSkeletonRect.origin.x += buttonSkeletonRect.size.width;
    UIButton *rsvpStatusButton = [[UIButton alloc] initWithFrame:buttonSkeletonRect];
    rsvpStatusButton.showsTouchWhenHighlighted = YES;
    [rsvpStatusButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
    [rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [rsvpStatusButton addTarget:self action:@selector(changeRsvpStatus:) forControlEvents:UIControlEventTouchDown];
    [rsvpStatusButton addTarget:self action:@selector(resetButtonBackGroundColor:) forControlEvents:UIControlEventTouchUpInside];
    [rsvpStatusButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [rsvpStatusButton setTitle:@"RSVP Status" forState:UIControlStateNormal];
    
    //add buttons to view
    [_buttonHolder addSubview:inviteButton];
    [_buttonHolder addSubview:rsvpStatusButton];
    
    //creating event title label and features
    NSString *eventTitle = [_eventDetails objectForKey:@"name"];
    _titleLabel = [[UILabel alloc] initWithFrame: eventImageView.frame];
    [_titleLabel setText:eventTitle];
    [_titleLabel setUserInteractionEnabled:NO];

    CGFloat fontSize = MIN(24,625/[eventTitle length]);
    UIFont *textFont = [UIFont fontWithName:@"Helvetica Neue" size:fontSize];
    NSLog (@"Font families: %@", [UIFont familyNames]);

    NSLog(@"%@",[textFont fontName]);
    [_titleLabel setTextColor:[UIColor whiteColor]];
    [_titleLabel setFont:textFont];
    [_titleLabel setTextAlignment:NSTextAlignmentLeft];
    CGRect tempRect = _titleLabel.frame;
    tempRect.origin.x += margin;
    _titleLabel.frame = tempRect;
    
    [eventImageView addSubview:_titleLabel];
    
    //initializing mapView and setting coordinates of location
    skeletonRect.size.height = frameSize.width/2;
    _mapView = [[GMSMapView alloc] initWithFrame:skeletonRect];
    
    NSDictionary *venueDict = _eventDetails[@"venue"];
    NSString *locationName = _eventDetails[@"location"];
    if (venueDict[@"latitude"]) {
        NSString *latString = venueDict[@"latitude"];
        NSString *lngString = venueDict[@"longitude"];
        double latitude = [latString doubleValue];
        double longitude = [lngString doubleValue];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        venueLocationCoordinate = coordinate;
        
        [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
  
    } else {
        
        MKGeocodingService *geocoder = [[MKGeocodingService alloc] init];
        
        [geocoder fetchGeocodeAddress:locationName completion:^(NSDictionary *geocode, NSError *error) {
            CLLocationCoordinate2D coordinate = [((CLLocation *)geocode[@"location"]) coordinate];
            venueLocationCoordinate = coordinate;
            [self moveMapCameraAndPlaceMarkerAtCoordinate:coordinate];
        }];
    }
    
    skeletonRect.origin.x +=margin;
    //if it is a host, add a button to start tracking
    if (_isHost) {
        skeletonRect.size = CGSizeMake(frameSize.width-2*margin, frameSize.width/5);
        _trackingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_trackingButton setBackgroundColor:[UIColor purpleColor]];
        _trackingButton.frame = skeletonRect;
        skeletonRect.origin.y += skeletonRect.size.height;
        [_trackingButton setTitle:@"Start Tracking" forState:UIControlStateNormal];
        [_trackingButton addTarget:self action:@selector(loadMapView:) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:_trackingButton];
    }
    
    //creating table view with event details and setting data source
    skeletonRect.size = CGSizeMake(frameSize.width-2*margin,frameSize.width);
    _detailsTable = [[UITableView alloc] initWithFrame:skeletonRect style:UITableViewStylePlain];
    [_detailsTable setDataSource:_dataSource];
    [_detailsTable setTableHeaderView:_mapView];
    
    //setting some UI aspects of tableview
    skeletonRect.size.height = _detailsTable.contentSize.height;
    _detailsTable.frame = skeletonRect;
    [_detailsTable.layer setCornerRadius:3];
    [_detailsTable.layer setBorderWidth:0.5];
    [_detailsTable.layer setBorderColor: [[UIColor colorWithWhite:0 alpha:0.3]CGColor]];
    [_detailsTable setUserInteractionEnabled:NO];
    [_detailsTable setScrollEnabled:NO];
    
    [_mainView addSubview:_detailsTable];
    
    [super viewDidLoad];
}

- (void)moveMapCameraAndPlaceMarkerAtCoordinate:(CLLocationCoordinate2D)coordinate
{
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude
                                                                longitude:coordinate.longitude
                                                                     zoom:14];
        [_mapView setCamera:camera];
        _mapView.myLocationEnabled = YES;
    
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
        venueLocationCoordinate = coordinate;
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


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _mainView;
}

-(void) tap: (UIGestureRecognizer*) gr {
    NSLog(@"%@", _mapViewController);
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
    void (^completionBlock)(NSString *newStatus) = (^(NSString *newStatus) {
        [[ParseDataStore sharedStore] event:_eventDetails[@"id"] changeRsvpStatusTo:newStatus completion:nil];
    });
    
    _statusTableController = [[FBEventStatusTableController alloc] initWithStatus:_eventDetails[@"rsvp_status"]
                                                                       completion:completionBlock];
    
    [self.navigationController pushViewController:[_statusTableController presentableViewController] animated:YES];
}

- (void) resetButtonBackGroundColor: (id) sender {
    UIButton *button = (UIButton *) sender;
    NSLog(@"%u",[button state]);
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1]];
}

- (void)initFriendsIDArray
{
    FBGraphObject *fbGraphObj = (FBGraphObject *)_eventDetails;
    NSArray *attendingFriends = fbGraphObj[@"attending"][@"data"];
    
    _friendsIDArray = [[NSMutableArray alloc] init];
    
    // Populate friendsIDArray with the ID's of
    // everyone attending event
    for (NSDictionary *friend in attendingFriends)
    {
        [_friendsIDArray addObject:(NSString *)friend[@"id"]];
        NSLog(@"%@", friend[@"id"]);
    }
    
}

- (void)loadMapView:(id)sender
{
    [[ParseDataStore sharedStore] startTrackingLocation];
    
    _mapViewController = [[ActiveEventMapViewController alloc] initWithFriendsDetails:nil venueLocationCoordinate:venueLocationCoordinate];
    [[self navigationController] pushViewController: _mapViewController animated:YES];
}


@end
