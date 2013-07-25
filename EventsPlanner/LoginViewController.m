//

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "_test_DetailsViewController.h"
#import "FBDataStore.h"

@implementation LoginViewController


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Facebook Profile";
    
    // Check if user is cached and linked to Facebook, if so, bypass login    
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        NSLog(@"already logged in");
        __block _test_DetailsViewController *viewController = [[_test_DetailsViewController alloc] init];
        [[FBDataStore sharedStore] fetchEventListDataWithCompletion:^(NSArray *eventData) {
            NSData *jsonArray = [NSJSONSerialization dataWithJSONObject:eventData
                                                                options:NSJSONWritingPrettyPrinted
                                                                  error:nil];
            NSString *eventDataString = [[NSString alloc] initWithData:jsonArray encoding:NSUTF8StringEncoding];
            [viewController setText:eventDataString];
            [self.navigationController pushViewController:viewController
                                                 animated:YES];
        }];
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
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"Uh oh. The user cancelled the Facebook login." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
        } else {
            if (user.isNew) {
                NSLog(@"User with facebook signed up and logged in!");
            } else {
                NSLog(@"User with facebook logged in!");
            }
            __block _test_DetailsViewController *viewController = [[_test_DetailsViewController alloc] init];
            [[FBDataStore sharedStore] fetchEventListDataWithCompletion:^(NSArray *eventData) {
                NSData *jsonArray = [NSJSONSerialization dataWithJSONObject:eventData
                                                                    options:NSJSONWritingPrettyPrinted
                                                                      error:nil];
                NSString *eventDataString = [[NSString alloc] initWithData:jsonArray encoding:NSUTF8StringEncoding];
                [viewController setText:eventDataString];
                [self.navigationController pushViewController:viewController
                                                     animated:YES];
            }];
        }
    }];
    
    [_activityIndicator startAnimating]; // Show loading indicator until login is finished
}

@end
