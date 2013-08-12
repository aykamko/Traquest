

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "ParseDataStore.h"
#import "EventsListController.h"
#import "ParseDataStore.h"

@interface LoginViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) EventsListController *eventsListController;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic,strong) UITextView *logo;
@property (nonatomic,strong) UITextView *logo2;
@property (nonatomic, strong) IBOutlet UIButton *loginButton;

@property (nonatomic, strong) NSMutableArray *userPastLocations;

- (IBAction)loginButtonTouchHandler:(id)sender;

@end

@implementation LoginViewController

#pragma mark - UIViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"firstBackground.png"]];

    // Check if user is cached and linked to Facebook, if so, bypass login
    [self drawLayout];
    if ([[ParseDataStore sharedStore] isLoggedIn]) {
        [self setEventsListView];
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
    [self.navigationController.navigationBar setTranslucent:NO];
    [super viewWillDisappear:animated];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Login mehtods



/* Login to facebook method */
- (IBAction)loginButtonTouchHandler:(id)sender  {
    
    // Show loading indicator until login is finished
    [_activityIndicator startAnimating];
    
    [[ParseDataStore sharedStore] logInWithCompletion:^{
        [_activityIndicator stopAnimating];
        [self setEventsListView];
    }];
    
   
}

- (void)setEventsListView
{
    [[ParseDataStore sharedStore] fetchEventListDataWithCompletion:^(NSArray *hostEvents, NSArray *guestEvents, NSArray *noReplyEvents) {
        
        _eventsListController = [[EventsListController alloc] initWithHostEvents:hostEvents guestEvents:guestEvents noReplyEvents:noReplyEvents];
        
        [self.navigationController pushViewController:[_eventsListController presentableViewController]
                                             animated:YES];
        
    }];
    
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray *)locations
{

       CLLocation* location = [locations lastObject];

    CLLocationCoordinate2D coordinate = [location coordinate];
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                           longitude:coordinate.longitude];

    [[PFUser currentUser] setObject:geoPoint forKey:@"location"];
    [_userPastLocations addObject:geoPoint];
 
        
    [[PFUser currentUser] saveInBackground];
}


- (void)drawLayout {
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
    [self.loginButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 43, 0, 0)];
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [self.loginButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *loginBottomConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                             attribute:NSLayoutAttributeBottom
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.loginButton
                                                                             attribute:NSLayoutAttributeBottom
                                                                            multiplier:1.0
                                                                              constant:180.0];
    NSLayoutConstraint *loginCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                              attribute:NSLayoutAttributeCenterX
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.loginButton
                                                                              attribute:NSLayoutAttributeCenterX
                                                                             multiplier:1.0
                                                                               constant:0.0];
    
    UIImage *normalStateImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"login-button-small" ofType:@"png"]];
    [self.loginButton setBackgroundImage:normalStateImg forState:UIControlStateNormal];
    
    UIImage *pressedStateImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"login-button-small-pressed" ofType:@"png"]];
    [self.loginButton setBackgroundImage:pressedStateImg forState:UIControlStateSelected];
    
    [self.loginButton addTarget:self
                         action:@selector(loginButtonTouchHandler:)
               forControlEvents:UIControlEventTouchUpInside];
        
    [self.view addSubview:description];
    [self.view addSubview:self.loginButton];
    [self.view addSubview:imageView];
    [self.view addSubview:_logo];
    [self.view addSubview:_logo2];
    
    [self.view addConstraints:@[loginBottomConstraint, loginCenterXConstraint]];
}

@end
