//
//  NSDate+TuyaSmart.h
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2018/12/25.
//  Copyright © 2018 fulang@tuya.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TUYA_MINUTE     60
#define TUYA_HOUR       3600
#define TUYA_DAY        86400
#define TUYA_WEEK       604800
#define TUYA_YEAR       31556926

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (TuyaSmart)

+ (NSCalendar *)tuya_currentCalendar;

// Short string utilities
- (NSString *)tuya_stringWithFormat: (NSString *) format;

- (BOOL)tuya_isToday;

// Decomposing dates
@property (readonly) NSInteger tuya_nearestHour;
@property (readonly) NSInteger tuya_hour;
@property (readonly) NSInteger tuya_minute;
@property (readonly) NSInteger tuya_seconds;
@property (readonly) NSInteger tuya_day;
@property (readonly) NSInteger tuya_month;
@property (readonly) NSInteger tuya_weekday;
@property (readonly) NSInteger tuya_nthWeekday; // e.g. 2nd Tuesday of the month == 2
@property (readonly) NSInteger tuya_year;

@end

NS_ASSUME_NONNULL_END
