//
//  UIImage+JTImageCrop.h
//
//  Created by james on 9/8/11.
//  http://ioscodesnippet.tumblr.com
//

#import <UIKit/UIKit.h>


@interface UIImage (JTImageCrop)

+ (UIImage *)imageWithImage:(UIImage *)image cropInRect:(CGRect)rect;

// define rect in proportional to the target image.
//
//  +--+--+
//  |A | B|
//  +--+--+
//  |C | D|
//  +--+--+
//
//  rect {0, 0, 1, 1} produce full image without cropping.
//  rect {0.5, 0.5, 0.5, 0.5} produce part D, etc.

+ (UIImage *)imageWithImage:(UIImage *)image cropInRelativeRect:(CGRect)rect;

+ (UIImage *)imageWithImage:(UIImage*)image scaledToWidth:(CGFloat)newWidth;

+ (UIImage *)imageWithImage:(UIImage *)image cropRectFromCenterOfSize:(CGSize)size;

+ (UIImage *)imageWithGradient: (CGSize) imageSize withColor1: (UIColor*) color1 withColor2: (UIColor*) color2 vertical:(BOOL) vertical;

+ (UIImage *)overlayImage: (UIImage *) image1 overImage: (UIImage *) image2;

+ (UIImage *)imageWithBackground:(UIColor *) color size: (CGSize) size;

@end
