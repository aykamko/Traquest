//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

@interface LoginViewController : UIViewController <CLLocationManagerDelegate>

@property PFObject *allUsers;

@end
