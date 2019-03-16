//
//  TYCameraCalendarView.h
//  TuyaSmartPublic
//
//  Created by 高森 on 16/8/17.
//  Copyright © 2016年 Tuya. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TYCameraCalendarView;

@protocol TYCameraCalendarViewDelegate <NSObject>

//切换月份
- (void)calendarView:(TYCameraCalendarView *)calendarView didSelectYear:(NSInteger)year month:(NSInteger)month;

//选定日期
- (void)calendarView:(TYCameraCalendarView *)calendarView didSelectYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day date:(NSDate *)date;

@end

@protocol TYCameraCalendarViewDataSource <NSObject>

- (BOOL)calendarView:(TYCameraCalendarView *)calendarView hasVideoOnYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;

@end

@interface TYCameraCalendarView : UIView

- (void)show:(NSDate *)date;
- (void)hide;

- (void)reloadData;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, weak) id<TYCameraCalendarViewDelegate> delegate;
@property (nonatomic, weak) id<TYCameraCalendarViewDataSource> dataSource;

@end

