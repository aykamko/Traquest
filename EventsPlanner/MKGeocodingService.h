//
//  MKGeocodingsService.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MKGeocodingService : NSObject

- (void)fetchGeocodeAddress:(NSString *)address
                 completion:(void (^)(NSDictionary *geocode, NSError *error))completionBlock;

@end
