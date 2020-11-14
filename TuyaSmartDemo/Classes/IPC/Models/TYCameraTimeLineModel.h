//
//  TYCameraTimeLineModel.h
//  TuyaSmartDemo
//
//  Created by 傅浪 on 2020/10/14.
//

#import <Foundation/Foundation.h>
#import <TuyaCameraUIKit/TuyaCameraUIKit.h>

@interface TYCameraTimeLineModel : NSObject <TuyaTimelineViewSource>

@property (nonatomic, assign) NSInteger startTime;

@property (nonatomic, assign) NSInteger stopTime;

@property (nonatomic, strong) NSDate *startDate;

@property (nonatomic, strong) NSDate *stopDate;

- (BOOL)containsPlayTime:(NSInteger)playTime;

@end

