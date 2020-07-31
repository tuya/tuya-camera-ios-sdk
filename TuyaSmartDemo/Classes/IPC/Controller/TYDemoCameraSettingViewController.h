//
//  TYDemoCameraSettingViewController.h
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/15.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPDemoBaseViewController.h"
#import <TuyaSmartCameraKit/TuyaSmartCameraKit.h>

@interface TYDemoCameraSettingViewController : TPDemoBaseViewController

@property (nonatomic, strong) NSString *devId;

@property (nonatomic, strong) TuyaSmartCameraDPManager *dpManager;

@end
