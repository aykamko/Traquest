// Used by +[UIImage imageWithImage:cropInRelativeRect]
CGRect CGRectTransformToRect(CGRect fromRect, CGRect toRect);

//
//  UIImage+JTImageCrop.m
//
//  Created by james on 9/8/11.
//  http://ioscodesnippet.tumblr.com
//

#import "UIImage+ImageCrop.h"

CGRect CGRectTransformToRect(CGRect fromRect, CGRect toRect) {
    CGPoint actualOrigin = (CGPoint){fromRect.origin.x * CGRectGetWidth(toRect), fromRect.origin.y * CGRectGetHeight(toRect)};
    CGSize  actualSize   = (CGSize){fromRect.size.width * CGRectGetWidth(toRect), fromRect.size.height * CGRectGetHeight(toRect)};
    return (CGRect){actualOrigin, actualSize};
}

@implementation UIImage (JTImageCrop)

+ (UIImage *)imageWithImage:(UIImage *)image cropRectFromCenterOfSize:(CGSize)size {
    NSParameterAssert(image != nil);
    if (CGSizeEqualToSize(size, image.size)) {
        return image;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1);
    
    CGFloat xOffset = -((image.size.width - size.width) / 2);
    CGFloat yOffset = -((image.size.height - size.height) / 2);
    
    [image drawAtPoint:(CGPoint){xOffset, yOffset}];
    UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return croppedImage;
}

+ (UIImage *)imageWithImage:(UIImage *)image cropInRect:(CGRect)rect {
    NSParameterAssert(image != nil);
    if (CGPointEqualToPoint(CGPointZero, rect.origin) && CGSizeEqualToSize(rect.size, image.size)) {
        return image;
    }
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1);
    [image drawAtPoint:(CGPoint){-rect.origin.x, -rect.origin.y}];
    UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return croppedImage;
}

+ (UIImage *)imageWithImage:(UIImage *)image cropInRelativeRect:(CGRect)rect {
    NSParameterAssert(image != nil);
    if (CGRectEqualToRect(rect, CGRectMake(0, 0, 1, 1))) {
        return image;
    }
    
    CGRect imageRect = (CGRect){CGPointZero, image.size};
    CGRect actualRect = CGRectTransformToRect(rect, imageRect);
    return [UIImage imageWithImage:image cropInRect:CGRectIntegral(actualRect)];
}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToWidth:(CGFloat)newWidth;
{
    CGSize newSize = CGSizeMake(newWidth, image.size.height * (newWidth / image.size.width));
    
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end