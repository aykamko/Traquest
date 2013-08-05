//
//  EventTableViewCell.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventTableViewCell.h"
#import "EventsCell.h"

#import "UIImage+ImageCrop.h"

@interface EventTableViewCell ()

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) UIImage *background;

@end

@implementation EventTableViewCell

- (instancetype) initWithTitle:(NSString *)title
                    rsvpStatus:(NSString *)status
                          date:(NSDate *)date
                    background:(UIImage *)background
               reuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        
        _title = title;
        _status = status;
        _date = date;
        _background = background;
        
        [self setBackgroundColor:[UIColor clearColor]];
        
    }
    return self;
}

- (void)layoutSubviews
{
    CGRect newBounds = CGRectMake(0, 1, self.bounds.size.width, self.bounds.size.height - 1);
    
    if (_background) {
        UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:newBounds];
        [backgroundView setContentMode:UIViewContentModeCenter];
        
        UIImage *scaledCroppedImg = [UIImage imageWithImage:_background scaledToWidth:[UIScreen mainScreen].bounds.size.width];
        scaledCroppedImg = [UIImage imageWithImage:scaledCroppedImg cropRectFromCenterOfSize:newBounds.size];
        [backgroundView setImage:scaledCroppedImg];
        
        [self setBackgroundView:backgroundView];
        [self addSubview:backgroundView];
    }

    UIView *translucentView = [[UIView alloc] initWithFrame:newBounds];
    [translucentView setBackgroundColor:[UIColor whiteColor]];
    [translucentView setAlpha:0.75];
    //[self addSubview:translucentView];
    
    EventsCell *cell = [[EventsCell alloc] initWithFrame:newBounds
                                                   title:_title
                                              rsvpStatus:_status
                                                    date:_date
                                              background:_background];
    [self addSubview:cell];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}

@end
