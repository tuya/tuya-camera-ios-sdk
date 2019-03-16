//
//  TuyaSmartHomeManager.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/1/3.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartDeviceManager.h"
#import <TuyaSmartHomeKit/TuyaSmartKit.h>

@interface TuyaSmartDeviceManager ()<TuyaSmartHomeManagerDelegate, TuyaSmartHomeDelegate> {
    NSMutableArray *_deviceList;
}

@property (nonatomic, strong) TuyaSmartHomeManager *homeManager;

@property (nonatomic, strong) NSArray *homeList;

@end

@implementation TuyaSmartDeviceManager

+ (instancetype)sharedManager {
    static TuyaSmartDeviceManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [TuyaSmartDeviceManager new];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _deviceList = [NSMutableArray array];
    }
    return self;
}

- (void)getAllDevice {
    NSMutableArray *deviceList = _deviceList;
    __weak typeof(self) weakSelf = self;
    [self.homeManager getHomeListWithSuccess:^(NSArray<TuyaSmartHomeModel *> *homes) {
        NSMutableArray *temp = [NSMutableArray array];
        [homes enumerateObjectsUsingBlock:^(TuyaSmartHomeModel *homeMode, NSUInteger idx, BOOL *stop) {
            TuyaSmartHome *home = [TuyaSmartHome homeWithHomeId:homeMode.homeId];
            [temp addObject:home];
            home.delegate = weakSelf;
            [home getHomeDetailWithSuccess:^(TuyaSmartHomeModel *homeModel) {
                [deviceList addObjectsFromArray:home.deviceList];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"deviceDidUpdate" object:nil];
            } failure:^(NSError *error) {
                NSLog(@"get home detail error: %@", error);
            }];
        }];
        weakSelf.homeList = temp.copy;
    } failure:^(NSError *error) {
        NSLog(@"get home list failure: %@", error);
    }];
}

#pragma mark - TuyaSmartHomeManagerDelegate

- (void)serviceConnectedSuccess {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MQTTDidConnected" object:nil];
}

#pragma mark - TuyaSmartHomeDelegate

- (void)home:(TuyaSmartHome *)home device:(TuyaSmartDeviceModel *)device dpsUpdate:(NSDictionary *)dps {
    NSLog(@"device: %@ did update dps: %@", device.name, dps);
}

- (NSArray *)deviceList {
    return [_deviceList copy];
}

- (TuyaSmartHomeManager *)homeManager {
    if (!_homeManager) {
        _homeManager = [TuyaSmartHomeManager new];
        _homeManager.delegate = self;
    }
    return _homeManager;
}

@end
