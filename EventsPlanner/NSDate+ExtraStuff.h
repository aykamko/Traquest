//
//  NSDate+ExtraStuff.h
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/13/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ExtraStuff)

+ (NSDate *)dateToNearestFifteenMinutes:(NSDate *)date;
+ (NSString *)prettyReadableStringFromDate:(NSDate *)date;
+ (NSDate *)dateFromISO8601String:(NSString *)dateString;

@end
