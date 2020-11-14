//
//  TuyaSmartCloudTimePieceModel+Timeline.m
//  TuyaSmartDemo
//
//  Created by 傅浪 on 2020/11/12.
//

#import "TuyaSmartCloudTimePieceModel+Timeline.h"

@implementation TuyaSmartCloudTimePieceModel (Timeline)

- (NSTimeInterval)startTimeIntervalSinceDate:(NSDate *)date {
    return [self.startDate timeIntervalSinceDate:date];
}

- (NSTimeInterval)stopTimeIntervalSinceDate:(NSDate *)date {
    return [self.endDate timeIntervalSinceDate:date];
}

- (BOOL)containsTime:(NSInteger)time {
    return time >= self.startTime && time <= self.endTime;
}

@end
