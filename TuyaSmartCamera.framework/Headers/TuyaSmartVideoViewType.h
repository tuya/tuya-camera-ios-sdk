//
//  TuyaSmartVideoViewType.h
//  TYCameraLibrary
//
//  Created by 傅浪 on 2018/6/12.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol TuyaSmartVideoViewType <NSObject>

/**
 video scale factory

 @param scaled scale factory
 */
- (void)tuya_setScaled:(float)scaled;

/**
 video offset

 @param offset offset point
 */
- (void)tuya_setOffset:(CGPoint)offset;

/**
 clear video content, and reset scale and offset
 */
- (void)tuya_clear;

@end
