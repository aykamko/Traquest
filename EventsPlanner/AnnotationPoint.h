//
//  AnnotationPoint.h
//  EventsPlanner
//
//  Created by Xian Sun on 8/9/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface AnnotationPoint : MKPointAnnotation
@property (nonatomic,strong) NSString *fbId;
-(id)initWithFbId: (NSString *) fbId;

@end
