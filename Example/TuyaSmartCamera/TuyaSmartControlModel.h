//
//  TuyaSmartControlModel.h
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2018/12/24.
//  Copyright © 2018 fulang@tuya.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TuyaSmartControlModel : NSObject

@property (nonatomic, strong) NSString *controlName;

@property (nonatomic, assign, getter=isSelected) BOOL selected;

@property (nonatomic, weak) id target;

@property (nonatomic, strong) NSString *action;

- (instancetype)initWithName:(NSString *)name target:(id)target action:(NSString *)action;

@end

NS_ASSUME_NONNULL_END
