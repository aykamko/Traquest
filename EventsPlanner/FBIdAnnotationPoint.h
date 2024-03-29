//
//  AnnotationPoint.h
//  EventsPlanner
//
//  Created by Xian Sun on 8/9/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface FBIdAnnotationPoint : MKPointAnnotation

@property (nonatomic, readonly) BOOL anonymous;
@property (nonatomic, strong) NSString *fbId;

- (id)initWithFbId:(NSString *)fbId anonymity:(BOOL)anonymity;

@end
