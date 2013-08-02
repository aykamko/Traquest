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
    
@end
