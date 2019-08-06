//
//  TYCameraRecordCell.m
//  TuyaSmartPublic
//
//  Created by 傅浪 on 2018/4/14.
//  Copyright © 2018 Tuya. All rights reserved.
//

#import "TYCameraRecordCell.h"

@implementation TYCameraRecordCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _iconImageView  = [[UIImageView alloc] initWithFrame:CGRectMake(20, 15.5, 41, 41)];
        _startTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 14, 80, 22)];
        _startTimeLabel.textColor = [UIColor blackColor];
    
        _durationLabel  = [[UILabel alloc] initWithFrame:CGRectMake(76, 38, 66, 20)];
        _durationLabel.textColor = [UIColor blackColor];
        
        [self addSubview:_iconImageView];
        [self addSubview:_startTimeLabel];
        [self addSubview:_durationLabel];
    }
    return self;
}

- (void)config:(NSDictionary *)timeslice {
//    ty_camera_record_video
    NSDate *startDate = timeslice[kTuyaSmartTimeSliceStartDate];
    NSDate *stopDate = timeslice[kTuyaSmartTimeSliceStopDate];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    formatter.dateFormat = @"HH:mm:ss";
    _iconImageView.image = [UIImage imageNamed:@"ty_camera_record_video"];
    _startTimeLabel.text = [formatter stringFromDate:startDate];
    _durationLabel.text  = [self _durationTimeStampWithStart:startDate end:stopDate];
    [_durationLabel sizeToFit];
}

- (NSString *)_durationTimeStampWithStart:(NSDate *)start end:(NSDate *)end {
    NSInteger duration = [end timeIntervalSinceDate:start];
    int h =(int)(duration / 60 / 60);
    int m = (duration / 60) % 60;
    int s = duration % 60;    
    return [NSString stringWithFormat:@"Duration：%02d:%02d:%02d", h, m, s];
}

@end
