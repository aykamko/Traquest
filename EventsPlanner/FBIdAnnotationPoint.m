//
//  AnnotationPoint.m
//  EventsPlanner
//
//  Created by Xian Sun on 8/9/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBIdAnnotationPoint.h"

@implementation FBIdAnnotationPoint

-(id)initWithFbId: (NSString *) fbId
{
    self = [super init];
    if(self){
        _fbId = fbId;
    }
    
    return self;
}

@end

