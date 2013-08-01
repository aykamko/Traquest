

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "FBDataStore.h"
#import "EventsListController.h"

@interface LoginViewController ()
@property (nonatomic, strong) EventsListController *eventsListController;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic,strong)UITextView *logo;
@property(nonatomic,strong)UITextView *logo2;
@property (nonatomic, strong) IBOutlet UIButton *loginButton;

- (IBAction)loginButtonTouchHandler:(id)sender;

@end

@implementation LoginViewController

#pragma mark - UIViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        //self.view.backgroundColor = [UIColor whiteColor];
        
        self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"firstBackground.png"]];
        [self setLayout];
      
    }
    return self;
}



- (void)viewDidLoad {

    [super viewDidLoad];
    self.title = @"Facebook Profile";
    _allUsers = [PFObject objectWithClassName:@"allUsers"];

    // Check if user is cached and linked to Facebook, if so, bypass login
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [self setEventsListView];
        [self getUserLocation];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)getUserLocation
{
    if ([PFUser currentUser])
    {
        _locationManager = [[CLLocationManager alloc] init];
        
        [_locationManager setDelegate:self];
        [_locationManager startUpdatingLocation];

    }
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
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

    CLLocationCoordinate2D coordinate = [location coordinate];
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                           longitude:coordinate.longitude];

    [[PFUser currentUser] setObject:geoPoint forKey:@"location"];
    [_userPastLocations addObject:geoPoint];
    
    [[PFUser currentUser] setObject:[NSNumber numberWithBool:NO]  forKey:@"trackingAllowed"];

    
}


-(void)setLayout{
    _logo=[[UITextView alloc]initWithFrame:CGRectMake(self.view.center.x-55, 150, 150, 50) ];
    _logo.text=@"Events";
    [_logo setTextColor:[UIColor blackColor]];
    [_logo setFont:[UIFont fontWithName:@"Noteworthy-Bold" size:30]];
    _logo.backgroundColor=[UIColor clearColor];
    _logo.editable=NO;
    _logo2=[[UITextView alloc]initWithFrame:CGRectMake(self.view.center.x-50, 180, 200, 50)];
    _logo2.text=@"Planner";
    [_logo setTextColor:[UIColor blackColor]];
    [_logo2 setBackgroundColor:[UIColor clearColor]];
    [_logo2 setFont:[UIFont fontWithName:@"Noteworthy-Bold" size:30]];
    _logo2.editable=NO;
    _logo2.scrollEnabled=NO;
    _logo.scrollEnabled=NO;


    

    
    
    _logo.transform=CGAffineTransformMakeRotation(-13*M_PI/180.0);
    _logo2.transform=CGAffineTransformMakeRotation(-14.5*M_PI/180.0);
    
    UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(self.view.center.x-100, 120, 200, 200)];
    [imageView setImage:[UIImage imageNamed:@"stickynote.png"]];
    
    UITextView *description=[[UITextView alloc]initWithFrame:CGRectMake(0, 0, 300, 50)];
    description.center=CGPointMake(self.view.center.x, self.view.center.y+200);
    description.backgroundColor=[UIColor clearColor];
    description.text=@"Login to view and plan your Facebook events!";
    [description setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:15]];
                          
    
    
    self.loginButton = [[UIButton alloc] init];
    [self.loginButton setBounds:CGRectMake(0, 0, 150, 50)];
    [self.loginButton setCenter:CGPointMake(self.view.center.x, self.view.center.y*1.5)];
    [self.loginButton setTitle:@"     Login" forState:UIControlStateNormal];
    
    UIImage *normalStateImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"login-button-small@2x" ofType:@"png"]];
    [self.loginButton setBackgroundImage:normalStateImg forState:UIControlStateNormal];
    
    UIImage *pressedStateImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"login-button-small-pressed@2x" ofType:@"png"]];
    [self.loginButton setBackgroundImage:pressedStateImg forState:UIControlStateSelected];
    
    [self.loginButton addTarget:self
                         action:@selector(loginButtonTouchHandler:)
               forControlEvents:UIControlEventTouchUpInside];
        
    [self.view addSubview:description];
    [self.view addSubview:self.loginButton];
    [self.view addSubview:imageView];
    [self.view addSubview:_logo];
    [self.view addSubview:_logo2];
}
@end
