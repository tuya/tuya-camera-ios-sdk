//
//  TuyaSmartSwitchCell.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/15.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

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
