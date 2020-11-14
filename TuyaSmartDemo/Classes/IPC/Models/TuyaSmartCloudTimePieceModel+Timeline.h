//
//  TuyaSmartCloudTimePieceModel+Timeline.h
//  TuyaSmartDemo
//
//  Created by 傅浪 on 2020/11/12.
//

#import <TuyaSmartCameraKit/TuyaSmartCameraKit.h>
#import <TuyaCameraUIKit/TuyaCameraUIKit.h>

@interface TuyaSmartCloudTimePieceModel (Timeline)<TuyaTimelineViewSource>

- (BOOL)containsTime:(NSInteger)time;

@end

