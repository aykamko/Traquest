//
//  NSDate+ExtraStuff.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/13/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "NSDate+ExtraStuff.h"

@implementation NSDate (ExtraStuff)

+ (NSDate *)dateToNearestFifteenMinutes:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit |
                                                         NSMonthCalendarUnit |
                                                         NSDayCalendarUnit |
                                                         NSHourCalendarUnit |
                                                         NSMinuteCalendarUnit)
                                               fromDate:date];
    [components setCalendar:calendar];
    NSInteger hour = components.hour;
    NSInteger minute = components.minute;

    if (minute < 15) {
        minute = 15;
    } else if (minute < 30) {
        minute = 30;
    } else if (minute < 45) {
        minute = 45;
    } else if (minute <= 59) {
        minute = 0;
        hour += 1;
    }

    components.hour = hour;
    components.minute = minute;

    NSDate *toNearestFifteenMinutes = [components date];
    return toNearestFifteenMinutes;
}

+ (NSString *)prettyReadableStringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    [dateFormatter setLenient:YES];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSString *baseDateString = [dateFormatter stringFromDate:date];
    NSRange range = NSMakeRange(baseDateString.length - 10, 2);
    NSString *dateString = [baseDateString stringByReplacingOccurrencesOfString:@","
                                                                     withString:@" at"
                                                                        options:0
                                                                          range:range];
    return dateString;
}

@end
