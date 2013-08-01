

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "FBDataStore.h"
#import "EventsListController.h"

@interface LoginViewController ()
@property (nonatomic, strong) EventsListController *eventsListController;
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation LoginViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Facebook Profile";
    
    // Check if user is cached and linked to Facebook, if so, bypass login    
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        
        [self setEventsListView];
        [self getUserLocation];
    }
}

-(void)getUserLocation
{
    if ([PFUser currentUser])
    {
        _locationManager = [[CLLocationManager alloc] init];
        
        [_locationManager setDelegate:self];
        [_locationManager startUpdatingLocation];
       

 //change

    }
}


#pragma mark - Login mehtods

/* Login to facebook method */
- (IBAction)loginButtonTouchHandler:(id)sender  {
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[@"user_events"];
    
    // Login PFUser using facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        [_activityIndicator stopAnimating]; // Hide loading indicator
        
        if (!user) {
            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"Uh oh. The user cancelled the Facebook login." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
        } else {
            [self setEventsListView];
        }
    }];
    
    [_activityIndicator startAnimating]; // Show loading indicator until login is finished
}

-(void)setEventsListView
{
    [[FBDataStore sharedStore] fetchEventListDataWithCompletion:^(NSArray *hostEvents, NSArray *guestEvents) {
        
        _eventsListController = [[EventsListController alloc] initWithHostEvents:hostEvents guestEvents:guestEvents];
        
        [self.navigationController pushViewController:[_eventsListController presentableViewController]
                                             animated:YES];
        
    }];
    
}

-(void) locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray *)locations
{

       CLLocation* location = [locations lastObject];
//      NSLog(@"%hhd", [CLLocationManager locationServicesEnabled]);
//    NSLog(@"%@", location);
    CLLocationCoordinate2D coordinate = [location coordinate];
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                           longitude:coordinate.longitude];
    //NSLog(@"%f,%f",geoPoint.latitude,geoPoint.longitude);
    [[PFUser currentUser] setObject:geoPoint forKey:@"location"];
    [_userPastLocations addObject:geoPoint];
    
    [[PFUser currentUser] setObject:[NSNumber numberWithBool:NO]  forKey:@"trackingAllowed"];
    
    
    
    NSDate* eventDate = location.timestamp;
    //NSLog(@"%@", location);
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    //self.userLocation = [[CLLocation alloc] init];
    if (abs(howRecent) < 15.0)
    {
        // If the event is recent, assign to userLocation and print
        // self.userLocation = location;
//        NSLog(@"latitude %+.6f, longitude %+.6f\n",
//              location.coordinate.latitude,
//              location.coordinate.longitude);
    }
    
}
@end
