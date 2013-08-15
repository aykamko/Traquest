//
//  FBGraphObject+FixEventCoverPhoto.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/13/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBGraphObject+FixEventCoverPhoto.h"
#import "UIImage+ImageCrop.h"

@implementation FBGraphObject (FixEventCoverPhoto)

- (void)fixEventCoverPhoto
{
    float scale = [UIScreen mainScreen].scale;
    CGSize defaultCoverSize = CGSizeMake([UIScreen mainScreen].bounds.size.width * scale, 120 * scale);
    
    if(!self[@"cover"]) {
        
        UIImage *mainImage = [UIImage imageNamed:@"eventCoverPhoto.png"];
        UIImage *coloring = [UIImage imageWithBackground:[UIColor colorWithWhite:0 alpha:0.3]
                                                    size:defaultCoverSize];
        UIImage *imageWithBackground = [UIImage overlayImage:coloring overImage:mainImage];
        UIImage *gradientImage = [UIImage
                                  imageWithGradient:defaultCoverSize
                                  withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]
                                  withColor2:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2]
                                  vertical:NO];
        self[@"cover"] = [UIImage overlayImage:gradientImage overImage:imageWithBackground];
        
    } else {
        
        NSURL *imageURL = [NSURL URLWithString:self[@"cover"][@"source"]];
        UIImage *mainImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
        UIImage *gradientImage = [UIImage
                                  imageWithGradient:defaultCoverSize
                                  withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]
                                  withColor2:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2]
                                  vertical:NO];
        self[@"cover"] = [UIImage overlayImage:gradientImage overImage:mainImage];
        
    }
}

@end
