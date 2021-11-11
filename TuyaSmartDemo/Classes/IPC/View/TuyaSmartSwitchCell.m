//
//  TuyaSmartSwitchCell.m
//  TuyaSmartCamera_Example
//
//  Copyright (c) 2014-2021 Tuya Inc. (https://developer.tuya.com/)

#import "TuyaSmartSwitchCell.h"

@implementation TuyaSmartSwitchCell

- (void)layoutSubviews {
    [super layoutSubviews];
    self.switchButton.center = CGPointMake(self.frame.size.width - 40, self.frame.size.height / 2);
}

- (void)setValueChangedTarget:(id)target selector:(SEL)selector value:(BOOL)value {
    self.switchButton.on = value;
    [self.switchButton addTarget:target action:selector forControlEvents:UIControlEventValueChanged];
}

- (UISwitch *)switchButton {
    if (!_switchButton) {
        _switchButton = [[UISwitch alloc] init];
        [self.contentView addSubview:_switchButton];
    }
    return _switchButton;
}

@end
