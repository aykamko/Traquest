//
//  EventTableViewCell.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/1/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventCell.h"
#import "EventCellContentView.h"

#import "UIImage+ImageCrop.h"

@interface EventCell ()
{
    EventCellContentView *_contentView;
}

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) UIImage *background;

@end

@implementation EventCell

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

-(void) setTitle:(NSString *)title
                  rsvpStatus:(NSString *)status
                        date:(NSDate *)date
                  background:(UIImage *)background
             reuseIdentifier:(NSString *)identifier {
    
    _title = title;
    _status = status;
    _date = date;
    _background = background;
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL reloadViewForiOS7 = NO;
    if (([[[UIDevice currentDevice] systemVersion] floatValue] > 6.1) && ([self isSelected] || [self isHighlighted])) {
        reloadViewForiOS7 = YES;
    }
   
    if (_contentView && !reloadViewForiOS7) {
        return;
    }
    
    CGRect newBounds = CGRectMake(0, 1, self.bounds.size.width, self.bounds.size.height - 1);
    
    if (_background) {
        UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:newBounds];
        [backgroundView setContentMode:UIViewContentModeCenter];
        
        UIImage *scaledCroppedImg = [UIImage imageWithImage:_background scaledToWidth:[UIScreen mainScreen].bounds.size.width];
        scaledCroppedImg = [UIImage imageWithImage:scaledCroppedImg cropRectFromCenterOfSize:newBounds.size];
        [backgroundView setImage:scaledCroppedImg];
        
        [self setBackgroundView:backgroundView];
    }
    
    _contentView = [[EventCellContentView alloc] initWithFrame:newBounds
                                                         title:_title
                                                    rsvpStatus:_status
                                                          date:_date
                                                    background:_background];
    [self addSubview:_contentView];
}

@end
