//
//  TuyaSmartSwitchCell.h
//  TuyaSmartCamera_Example
//
//  Copyright (c) 2014-2021 Tuya Inc. (https://developer.tuya.com/)

#import <UIKit/UIKit.h>

@interface TuyaSmartSwitchCell : UITableViewCell

@property (nonatomic, strong) UISwitch *switchButton;

- (void)setValueChangedTarget:(id)target selector:(SEL)selector value:(BOOL)value;

@end
