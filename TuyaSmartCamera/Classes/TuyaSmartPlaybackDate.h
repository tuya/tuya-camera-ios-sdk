//
//  TuyaSmartPlaybackDate.h
//  TuyaSmartCamera
//
//  Created by 傅浪 on 2019/2/16.
//

#import <Foundation/Foundation.h>

@interface TuyaSmartPlaybackDate : NSObject

@property (nonatomic, assign) NSInteger year;

@property (nonatomic, assign) NSInteger month;

@property (nonatomic, assign) NSInteger day;

+ (instancetype)playbackDateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;

+ (instancetype)playbackDateWithDate:(NSDate *)date;

+ (BOOL)isToday:(TuyaSmartPlaybackDate *)date;

@end
