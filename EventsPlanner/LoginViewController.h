//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property NSDictionary *eventsDictionary;
- (IBAction)loginButtonTouchHandler:(id)sender;

@end
