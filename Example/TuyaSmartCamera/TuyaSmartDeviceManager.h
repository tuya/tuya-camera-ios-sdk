//
//  TuyaSmartHomeManager.h
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/1/3.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TuyaSmartDeviceManager : NSObject

@property (nonatomic, strong, readonly) NSArray *deviceList;

+ (instancetype)sharedManager;

- (void)getAllDevice;

@end

NS_ASSUME_NONNULL_END
