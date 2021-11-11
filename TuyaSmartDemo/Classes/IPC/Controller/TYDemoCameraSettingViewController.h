//
//  TYDemoCameraSettingViewController.h
//  TuyaSmartCamera_Example
//
//  Copyright (c) 2014-2021 Tuya Inc. (https://developer.tuya.com/)

#import <UIKit/UIKit.h>
#import "TPDemoBaseViewController.h"
#import <TuyaSmartCameraKit/TuyaSmartCameraKit.h>

@interface TYDemoCameraSettingViewController : TPDemoBaseViewController

@property (nonatomic, strong) NSString *devId;

@property (nonatomic, strong) TuyaSmartCameraDPManager *dpManager;

@end
