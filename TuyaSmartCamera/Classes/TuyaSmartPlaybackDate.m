//
//  TuyaSmartPlaybackDate.m
//  TuyaSmartCamera
//
//  Created by 傅浪 on 2019/2/16.
//

#import "TuyaSmartPlaybackDate.h"

static const unsigned CalendarUnits = (NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekOfYear |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal);

NSCalendar * currentCalendar() {
    static NSCalendar *sharedCalendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCalendar = [NSCalendar autoupdatingCurrentCalendar];
    });
    return sharedCalendar;
}

@implementation TuyaSmartPlaybackDate

- (instancetype)init {
    return [self initWithDate:[NSDate new]];
}

- (instancetype)initWithDate:(NSDate *)date {
    if (self = [super init]) {
        NSDateComponents *components = [currentCalendar() components:CalendarUnits fromDate:date];
        _year = components.year;
        _month = components.month;
        _day = components.day;
    }
    return self;
}

+ (instancetype)playbackDateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    TuyaSmartPlaybackDate *date = [[self alloc] init];
    date.year = year;
    date.month = month;
    date.day = day;
    return date;
}

+ (instancetype)playbackDateWithDate:(NSDate *)date {
    return [[self alloc] initWithDate:date];
}

+ (BOOL)isToday:(TuyaSmartPlaybackDate *)date {
    TuyaSmartPlaybackDate *today = [TuyaSmartPlaybackDate new];
    return today.year == date.year && today.month == date.month && today.day == date.day;
}

@end
