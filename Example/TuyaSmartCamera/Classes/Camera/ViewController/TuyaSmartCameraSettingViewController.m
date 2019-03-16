//
//  TuyaSmartCameraSettingViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/15.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartCameraSettingViewController.h"

@interface TuyaSmartCameraSettingViewController ()

@property (nonatomic, assign) BOOL moveDetectMode;

@end

@implementation TuyaSmartCameraSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getDeviceInfo];
}

- (void)getDeviceInfo {
    
    [self.dpManager valueForDP:TuyaSmartCameraRecordModeDPName success:^(id result) {
        NSLog(@"");
    } failure:^(NSError *error) {
        
    }];
}

- (void)initData {
    NSMutableArray *dataSource = [NSMutableArray new];
    
}

@end
