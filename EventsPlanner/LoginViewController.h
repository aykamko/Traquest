//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

@interface LoginViewController : UIViewController <CLLocationManagerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property NSDictionary *eventsDictionary;
@property (nonatomic,strong) NSMutableArray *userPastLocations;
- (IBAction)loginButtonTouchHandler:(id)sender;
@property PFObject *allUsers;



@end
