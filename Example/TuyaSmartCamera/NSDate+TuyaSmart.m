//
//  NSDate+TuyaSmart.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2018/12/25.
//  Copyright © 2018 fulang@tuya.com. All rights reserved.
//

#import "NSDate+TuyaSmart.h"

static const unsigned tuya_componentFlags = (NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekOfYear |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal);

@implementation NSDate (TuyaSmart)

+ (NSCalendar *)tuya_currentCalendar
{
    static NSCalendar *sharedCalendar = nil;
    if (!sharedCalendar)
        sharedCalendar = [NSCalendar autoupdatingCurrentCalendar];
    return sharedCalendar;
}

#pragma mark - String Properties
- (NSString *)tuya_stringWithFormat: (NSString *) format {
    NSDateFormatter *formatter = [NSDateFormatter new];
    //    formatter.locale = [NSLocale currentLocale]; // Necessary?
    formatter.dateFormat = format;
    return [formatter stringFromDate:self];
}



- (BOOL)tuya_isEqualToDateIgnoringTime: (NSDate *) aDate
{
    NSDateComponents *components1 = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:self];
    NSDateComponents *components2 = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:aDate];
    return ((components1.year == components2.year) &&
            (components1.month == components2.month) &&
            (components1.day == components2.day));
}


- (BOOL)tuya_isToday
{
    return [self tuya_isEqualToDateIgnoringTime:[NSDate date]];
}


#pragma mark - Decomposing Dates

- (NSInteger)tuya_nearestHour
{
    NSTimeInterval aTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] + TUYA_MINUTE * 30;
    NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
    NSDateComponents *components = [[NSDate tuya_currentCalendar] components:NSCalendarUnitHour fromDate:newDate];
    return components.hour;
}

- (NSInteger)tuya_hour
{
    NSDateComponents *components = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:self];
    return components.hour;
}

- (NSInteger)tuya_minute
{
    NSDateComponents *components = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:self];
    return components.minute;
}

- (NSInteger)tuya_seconds
{
    NSDateComponents *components = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:self];
    return components.second;
}

- (NSInteger)tuya_day
{
    NSDateComponents *components = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:self];
    return components.day;
}

- (NSInteger)tuya_month
{
    NSDateComponents *components = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:self];
    return components.month;
}

- (NSInteger)tuya_weekday
{
    NSDateComponents *components = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:self];
    return components.weekday;
}

- (NSInteger)tuya_nthWeekday // e.g. 2nd Tuesday of the month is 2
{
    NSDateComponents *components = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:self];
    return components.weekdayOrdinal;
}

- (NSInteger)tuya_year
{
    NSDateComponents *components = [[NSDate tuya_currentCalendar] components:tuya_componentFlags fromDate:self];
    return components.year;
}

@end
