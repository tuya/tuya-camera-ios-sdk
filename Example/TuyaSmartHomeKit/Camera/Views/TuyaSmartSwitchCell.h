//
//  TuyaSmartSwitchCell.h
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/15.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TuyaSmartSwitchCell : UITableViewCell

@property (nonatomic, strong) UISwitch *switchButton;

- (void)setValueChangedTarget:(id)target selector:(SEL)selector value:(BOOL)value;

@end
