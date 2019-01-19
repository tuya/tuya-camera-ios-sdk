//
//  TuyaSmartControlCollectionViewCell.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2018/12/24.
//  Copyright © 2018 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartControlCollectionViewCell.h"

@implementation TuyaSmartControlCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.frame = self.bounds;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.textColor = [UIColor blackColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _textLabel;
}

@end
