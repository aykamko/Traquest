//
//  GuestAnnotationView.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/19/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "GuestAnnotationView.h"

@interface GuestAnnotationView ()

@property (nonatomic, strong) UIImage *guestAnnotationImage;
@property (nonatomic) CGRect savedFrame;

@property (nonatomic) BOOL zeroFrame;

@end

@implementation GuestAnnotationView

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.guestAnnotationImage = [UIImage imageNamed:@"guest-location.png"];
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    if (newSuperview) {
        self.image = self.guestAnnotationImage;
        
        self.savedFrame = self.frame;
        self.frame = CGRectMake(CGRectGetMidX(self.savedFrame), CGRectGetMidY(self.savedFrame), 0, 0);
    }
}

- (void)didMoveToSuperview
{
    if (self.superview) {
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.frame = self.savedFrame;
        } completion:nil];
    }
//        [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            NSLog(@"%@", NSStringFromCGRect(self.frame));
//            self.frame = CGRectMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame), 0, 0);
//            self.zeroFrame = YES;
//        } completion:nil];
//    }
    
    [super didMoveToSuperview];
}

//- (void)removeFromSuperview
//{
//    if (self.superview) {
//        [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            self.bounds = CGRectMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame), 0, 0);
//        } completion:^(BOOL finished) {
//            [super removeFromSuperview];
//        }];
//    } else {
//        [super removeFromSuperview];
//    }
//}

@end
