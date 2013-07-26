

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "FBDataStore.h"
#import "EventsListController.h"

@interface LoginViewController ()
@property (nonatomic, strong) EventsListController *eventsListController;
@end

@implementation LoginViewController



#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Facebook Profile";
    
    // Check if user is cached and linked to Facebook, if so, bypass login    
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
         [self setEventsListView];
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


-(void)setEventsListView{
    [[FBDataStore sharedStore] fetchEventListDataWithCompletion:^(NSArray *hostEvents, NSArray *guestEvents) {
        _eventsListController = [[EventsListController alloc] initWithHostEvent:hostEvents guestEvents:guestEvents];
        [self.navigationController pushViewController:[_eventsListController presentableViewController]
                                             animated:YES];
        
        
        
    }];
    
}
@end
