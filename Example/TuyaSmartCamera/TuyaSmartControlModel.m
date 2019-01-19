//
//  TuyaSmartControlModel.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2018/12/24.
//  Copyright © 2018 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartControlModel.h"

@implementation TuyaSmartControlModel

- (instancetype)initWithName:(NSString *)name target:(id)target action:(NSString *)action {
    if (self = [super init]) {
        _controlName = name;
        _target = target;
        _action = action;
    }
    return self;
}

@end
