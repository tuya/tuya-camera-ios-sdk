//
//  TYCameraCalendarCollectionViewCell.m
//  TuyaSmartPublic
//
//  Created by 高森 on 16/8/18.
//  Copyright © 2016年 Tuya. All rights reserved.
//

#import "TYCameraCalendarCollectionViewCell.h"

@implementation TYCameraCalendarCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLabel.frame = self.bounds;
}

@end
