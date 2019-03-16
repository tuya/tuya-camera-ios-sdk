//
//  TYCameraRecordCell.h
//  TuyaSmartPublic
//
//  Created by 傅浪 on 2018/4/14.
//  Copyright © 2018 Tuya. All rights reserved.
//



#import <UIKit/UIKit.h>

@interface TYCameraRecordCell : UITableViewCell

@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UILabel *startTimeLabel;

@property (nonatomic, strong) UILabel *durationLabel;

- (void)config:(NSDictionary *)timeslice;

@end
