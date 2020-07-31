//
//  TYDemoCameraPanelManager.m
//  TuyaSmartDemo
//
//  Created by 傅浪 on 2020/7/6.
//

#import "TYDemoCameraPanelManager.h"
#import <TuyaSmartDeviceKit/TuyaSmartDeviceKit.h>
#import "TYDemoCameraViewController.h"
#import "TPDemoUtils.h"

@implementation TYDemoCameraPanelManager

+ (instancetype)sharedManager {
    static TYDemoCameraPanelManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [self new];
    });
    return _instance;
}

+ (void)load {
    [[TYDemoConfiguration sharedInstance] registService:@protocol(TYDemoPanelControlProtocol) withImpl:[self sharedManager]];
}

- (void)gotoPanelControlDevice:(TuyaSmartDeviceModel *)device group:(TuyaSmartGroupModel *)group {
    if (![device.category isEqualToString:@"sp"]) {
        return;
    }
    UIViewController *vc = [[TYDemoCameraViewController alloc] initWithDeviceId:device.devId];
    [tp_topMostViewController().navigationController pushViewController:vc animated:YES];
}

@end
