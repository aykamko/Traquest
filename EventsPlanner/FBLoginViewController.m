

#import "FBLoginViewController.h"
#import "ParseDataStore.h"
#import "EventsListController.h"
#import "Toast+UIView.h"

@interface FBLoginViewController ()

@property (nonatomic, strong) EventsListController *eventsListController;
@property (nonatomic, strong) UILabel *logoLabel;
@property (nonatomic, strong) UIButton *loginButton;

- (IBAction)loginButtonTouchHandler:(id)sender;

@end

@implementation FBLoginViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    UIImage *backgroundImage = [UIImage imageNamed:@"loginBackgroundIPhonePortrait.png"];
    self.view = [[UIImageView alloc] initWithImage:backgroundImage];
    [self.view setUserInteractionEnabled:YES];

    // Check if user is cached and linked to Facebook, if so, bypass login
    [self drawLayout];
    if ([[ParseDataStore sharedStore] isLoggedIn]) {
        [self.view makeToastActivity];
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
#pragma mark login method
/* Login to facebook method */
- (IBAction)loginButtonTouchHandler:(id)sender  {
    
    [self.loginButton setUserInteractionEnabled:NO];
    // Show loading indicator until login is finished
    [[ParseDataStore sharedStore] logInWithCompletion:^{
        [self.view makeToastActivity];
        [self setEventsListView];
        [self.loginButton setUserInteractionEnabled:YES];
    }];
   
}
#pragma mark List View Methods
- (void)setEventsListView
{

    [[ParseDataStore sharedStore] fetchAllEventListDataWithCompletion:^(NSArray *activeHostEvents,
                                                                        NSArray *activeGuestEvents,
                                                                        NSArray *hostEvents,
                                                                        NSArray *guestEvents,
                                                                        NSArray *maybeAttendingEvents,
                                                                        NSArray *noReplyEvents) {
        
        self.eventsListController = [[EventsListController alloc] initWithActiveHostEvents:activeHostEvents
                                                                         activeGuestEvents:activeGuestEvents
                                                                                hostEvents:hostEvents
                                                                           attendingEvents:guestEvents
                                                                          notRepliedEvents:noReplyEvents
                                                                            maybeAttending:maybeAttendingEvents];
        
        [[[_eventsListController presentableViewController] navigationItem] setHidesBackButton:YES];

        [self.view hideToastActivity];
        [self.navigationController pushViewController:[_eventsListController presentableViewController]
                                             animated:YES];

    }];
    
}

#pragma mark Constraint Methods
- (void)drawLayout {
    
    NSMutableDictionary *viewDict = [[NSMutableDictionary alloc] init];
    
    UIView *containerView = [[UIView alloc] init];
    [containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [viewDict addEntriesFromDictionary:@{ @"containerView":containerView }];
    [containerView setBackgroundColor:[UIColor clearColor]];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"post-it-note.png"]];
    [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [viewDict addEntriesFromDictionary:@{ @"imageView":imageView }];
    [containerView addSubview:imageView];
    [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:imageView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0.0]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:viewDict]];
    
    self.loginButton = [[UIButton alloc] init];
    [self.loginButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [viewDict addEntriesFromDictionary:@{ @"loginButton":self.loginButton }];
    
    UIImage *baseNormalStateImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                                    pathForResource:@"login-button-small"
                                                                    ofType:@"png"]];
    UIImage *normalStateImg = [baseNormalStateImg resizableImageWithCapInsets:UIEdgeInsetsMake(0, 100, 0, 10)];
    [self.loginButton setBackgroundImage:normalStateImg forState:UIControlStateNormal];
    
    UIImage *basePressedStateImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                                 pathForResource:@"login-button-small-pressed"
                                                                 ofType:@"png"]];
    UIImage *pressedStateImg = [basePressedStateImg resizableImageWithCapInsets:UIEdgeInsetsMake(0, 100, 0, 10)];
    [self.loginButton setBackgroundImage:pressedStateImg forState:UIControlStateSelected];
    
    [self.loginButton addConstraint:[NSLayoutConstraint constraintWithItem:self.loginButton
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:baseNormalStateImg.size.height]];
    
    [self.loginButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 43, 0, 0)];
    [self.loginButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [self.loginButton setTitle:@"Log In With Facebook" forState:UIControlStateNormal];
    
    [self.loginButton addTarget:self
                         action:@selector(loginButtonTouchHandler:)
               forControlEvents:UIControlEventTouchUpInside];
    
    [containerView addSubview:self.loginButton];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(20)-[loginButton]-(20)-|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:viewDict]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]-(20)-[loginButton]|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:viewDict]];
    
    [self.view addSubview:containerView];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                              attribute:NSLayoutAttributeCenterY
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:containerView
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:1.0
                                                               constant:0.0]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[containerView]-|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:viewDict]];
    
//    NSString *logoLabelText = @"Events\nPlanner";
//    UIFont *logoLabelFont = [UIFont fontWithName:@"Noteworthy-Bold" size:30];
//    CGSize sizeOfText = [logoLabelText sizeWithFont:logoLabelFont
//                                  constrainedToSize:CGSizeMake(1000.0f, 1000.0f)
//                                      lineBreakMode:NSLineBreakByWordWrapping];
////    
////    self.logoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, sizeOfText.width, sizeOfText.height)];
//    [self.logoLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
//    [viewDict addEntriesFromDictionary:@{ @"logoLabel":self.logoLabel }];
//    self.logoLabel.numberOfLines = 2;
//    self.logoLabel.textAlignment = NSTextAlignmentCenter;
//    self.logoLabel.text = logoLabelText;
//    self.logoLabel.font = logoLabelFont;
//    self.logoLabel.textColor = [UIColor blackColor];
//    self.logoLabel.backgroundColor = [UIColor clearColor];
    
//    self.logoLabel.transform = CGAffineTransformMakeRotation(-13 * M_PI/180.0);
//    [imageView addSubview:self.logoLabel];
//    [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView
//                                                          attribute:NSLayoutAttributeCenterX
//                                                          relatedBy:NSLayoutRelationEqual
//                                                             toItem:self.logoLabel
//                                                          attribute:NSLayoutAttributeCenterX
//                                                         multiplier:1.0
//                                                           constant:0.0]];
//    [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView
//                                                          attribute:NSLayoutAttributeCenterY
//                                                          relatedBy:NSLayoutRelationEqual
//                                                             toItem:self.logoLabel
//                                                          attribute:NSLayoutAttributeCenterY
//                                                         multiplier:1.0
//                                                           constant:0.0]];
//
    
}

@end
