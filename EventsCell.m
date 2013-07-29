//
//  EventsCell.m
//  EventsPlanner
//
//  Created by Xian Sun on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "EventsCell.h"
@interface EventsCell()
@property (nonatomic,strong) NSArray *guestEvents;
@property (nonatomic, strong)NSArray *hostEvents;
@end

@implementation EventsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier guestEvents:(NSArray *)guestEvents hostEvents:(NSArray *)hostEvents indexPath:(NSIndexPath *)indexPath
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _guestEvents=guestEvents;
        _hostEvents=hostEvents;
        _eventTitle=[[UILabel alloc]initWithFrame:CGRectMake(60.0, 0.0, 200.0, 25.0)];
        _eventDate=[[UILabel alloc]initWithFrame:CGRectMake(60.0, 27.0, 200.0, 15.0)];

        if(indexPath.section==0){
            _eventTitle.text=[[_hostEvents objectAtIndex:indexPath.row] objectForKey:@"name"];
            NSString *startTime=[[_hostEvents objectAtIndex:indexPath.row]objectForKey:@"start_time"];
            NSString *date1=[startTime substringWithRange:NSMakeRange(0, 4)];
            NSString *date2=[startTime substringWithRange:NSMakeRange(5, 2)];
            NSString *date3=[startTime substringWithRange:NSMakeRange(8, 2)];
            NSString *rsvp=[[_hostEvents objectAtIndex:indexPath.row]objectForKey:@"rsvp_status"];
            _eventDate.text=[NSString stringWithFormat:@"%@/%@/%@        status: %@",date2,date3,date1,rsvp];
            
            NSString *imageURL=[[[[_hostEvents objectAtIndex:indexPath.row]objectForKey:@"picture"]objectForKey:@"data"]objectForKey:@"url"];;
            NSData *imageData=[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
            UIImage *image=[UIImage imageWithData:imageData];
            self.imageView.image=image;

        }
        
        else{
            _eventTitle.text=[[_guestEvents objectAtIndex:indexPath.row]objectForKey:@"name"];
            NSString *startTime=[[_guestEvents objectAtIndex:indexPath.row]objectForKey:@"start_time"];
            NSString *date1=[startTime substringWithRange:NSMakeRange(0, 4)];
            NSString *date2=[startTime substringWithRange:NSMakeRange(5, 2)];
            NSString *date3=[startTime substringWithRange:NSMakeRange(8, 2)];
            NSString *rsvp=[[_guestEvents objectAtIndex:indexPath.row]objectForKey:@"rsvp_status"];
            _eventDate.text=[NSString stringWithFormat:@"%@/%@/%@        status: %@",date2,date3,date1,rsvp];
            
            NSString *imageURL=[[[[_guestEvents objectAtIndex:indexPath.row]objectForKey:@"picture"]objectForKey:@"data"]objectForKey:@"url"];;
            NSData *imageData=[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
            UIImage *image=[UIImage imageWithData:imageData];
            self.imageView.image=image;


        }
        
        
        
        _eventTitle.textColor=[UIColor blueColor];
        [_eventTitle setFont:[UIFont fontWithName:@"American Typewriter" size:18]];
        [_eventDate setFont:[UIFont fontWithName:@"TimesNewRomanPSMT" size:10]];
        [_eventTitle setBackgroundColor:[UIColor clearColor]];
        [_eventDate setBackgroundColor:[UIColor clearColor]];
        [self.contentView addSubview:_eventTitle];
        [self.contentView addSubview:_eventDate];
        
       
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}

@end
