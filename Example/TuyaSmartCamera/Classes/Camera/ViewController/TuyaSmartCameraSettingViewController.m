//
//  TuyaSmartCameraSettingViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/15.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartCameraSettingViewController.h"
#import "TuyaSmartSwitchCell.h"
#import "TuyaSmartSDCardViewController.h"

#define kTitle  @"title"
#define kValue  @"value"
#define kAction @"action"
#define kArrow  @"arrow"
#define kSwitch @"switch"

@interface TuyaSmartCameraSettingViewController ()<TuyaSmartCameraDPObserver>

@property (nonatomic, assign) BOOL indicatorOn;

@property (nonatomic, assign) BOOL flipOn;

@property (nonatomic, assign) BOOL osdOn;

@property (nonatomic, assign) BOOL privateOn;

@property (nonatomic, strong) TuyaSmartCameraNightvision nightvisionState;

@property (nonatomic, strong) TuyaSmartCaemraPIR pirState;

@property (nonatomic, assign) BOOL motionDetectOn;

@property (nonatomic, strong) TuyaSmartCameraMotion motionSensitivity;

@property (nonatomic, assign) BOOL decibelDetectOn;

@property (nonatomic, strong) TuyaSmartCameraDecibel decibelSensitivity;

@property (nonatomic, assign) TuyaSmartCameraSDCardStatus sdCardStatus;

@property (nonatomic, assign) BOOL sdRecordOn;

@property (nonatomic, strong) TuyaSmartCameraRecordMode recordMode;

@property (nonatomic, assign) BOOL batteryLockOn;

@property (nonatomic, strong) TuyaSmartCameraPowerMode powerMode;

@property (nonatomic, assign) NSInteger electricity;

@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation TuyaSmartCameraSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    [self.dpManager addObserver:self];
    [self.tableView registerClass:[TuyaSmartSwitchCell class] forCellReuseIdentifier:@"switchCell"];
    [self getDeviceInfo];
}

- (void)getDeviceInfo {
    WEAKSELF_AT
    dispatch_group_t group = dispatch_group_create();
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicIndicatorDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraBasicIndicatorDPName success:^(id result) {
            weakSelf_AT.indicatorOn = [result boolValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicFlipDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraBasicFlipDPName success:^(id result) {
            weakSelf_AT.flipOn = [result boolValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicOSDDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraBasicOSDDPName success:^(id result) {
            weakSelf_AT.osdOn = [result boolValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicPrivateDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraBasicPrivateDPName success:^(id result) {
            weakSelf_AT.privateOn = [result boolValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicNightvisionDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraBasicNightvisionDPName success:^(id result) {
            weakSelf_AT.nightvisionState = result;
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicPIRDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraBasicPIRDPName success:^(id result) {
            weakSelf_AT.pirState = result;
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraMotionDetectDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraMotionDetectDPName success:^(id result) {
            weakSelf_AT.motionDetectOn = [result boolValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraMotionSensitivityDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraMotionSensitivityDPName success:^(id result) {
            weakSelf_AT.motionSensitivity = result;
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraDecibelDetectDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraDecibelDetectDPName success:^(id result) {
            weakSelf_AT.decibelDetectOn = [result boolValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraDecibelSensitivityDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraDecibelSensitivityDPName success:^(id result) {
            weakSelf_AT.decibelSensitivity = result;
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraSDCardStatusDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraSDCardStatusDPName success:^(id result) {
            weakSelf_AT.sdCardStatus = [result integerValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraSDCardRecordDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraSDCardRecordDPName success:^(id result) {
            weakSelf_AT.sdRecordOn = [result boolValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraRecordModeDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraRecordModeDPName success:^(id result) {
            weakSelf_AT.recordMode = result;
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraWirelessBatteryLockDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraWirelessBatteryLockDPName success:^(id result) {
            weakSelf_AT.batteryLockOn = [result boolValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraWirelessPowerModeDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraWirelessPowerModeDPName success:^(id result) {
            weakSelf_AT.powerMode = result;
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraWirelessElectricityDPName]) {
        dispatch_group_enter(group);
        [self.dpManager valueForDP:TuyaSmartCameraWirelessElectricityDPName success:^(id result) {
            weakSelf_AT.electricity = [result integerValue];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    [self reloadData];
}

- (void)reloadData {
    NSMutableArray *dataSource = [NSMutableArray new];
    NSMutableArray *section0 = [NSMutableArray new];
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicIndicatorDPName]) {
        [section0 addObject:@{kTitle:@"指示灯", kValue: @(self.indicatorOn), kAction: @"indicatorAction:", kSwitch: @"1"}];
    }
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicFlipDPName]) {
        [section0 addObject:@{kTitle: @"画面翻转", kValue: @(self.flipOn), kAction: @"flipAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicOSDDPName]) {
        [section0 addObject:@{kTitle: @"时间水印", kValue: @(self.osdOn), kAction: @"osdAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicPrivateDPName]) {
        [section0 addObject:@{kTitle: @"隐私模式", kValue: @(self.privateOn), kAction: @"privateAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicNightvisionDPName]) {
        NSString *text = [self nightvisionText:self.nightvisionState];
        [section0 addObject:@{kTitle: @"红外夜视", kValue: text, kAction: @"nightvisionAction", kArrow: @"1"}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraBasicPIRDPName]) {
        NSString *text = [self pirText:self.pirState];
        [section0 addObject:@{kTitle: @"PIR", kValue: text, kAction: @"pirAction", kArrow: @"1"}];
    }
    
    if (section0.count > 0) {
        [dataSource addObject:@{kTitle:@"基础设置", kValue: section0.copy}];
    }
    
    NSMutableArray *section1 = [NSMutableArray new];
    if ([self.dpManager isSurpportDP:TuyaSmartCameraMotionDetectDPName]) {
        [section1 addObject:@{kTitle: @"移动侦测", kValue: @(self.motionDetectOn), kAction: @"motionDetectAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraMotionSensitivityDPName] && self.motionDetectOn) {
        NSString *text = [self motionSensitivityText:self.motionSensitivity];
        [section1 addObject:@{kTitle: @"移动侦测灵敏度", kValue: text, kAction: @"motionSensitivityAction", kArrow: @"1"}];
    }
    if (section1.count > 0) {
        [dataSource addObject:@{kTitle: @"移动侦测", kValue: section1.copy}];
    }
    
    NSMutableArray *section2 = [NSMutableArray new];
    if ([self.dpManager isSurpportDP:TuyaSmartCameraDecibelDetectDPName]) {
        [section2 addObject:@{kTitle: @"声音侦测", kValue: @(self.decibelDetectOn), kAction: @"decibelDetectAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraDecibelSensitivityDPName] && self.decibelDetectOn) {
        NSString *text = [self decibelSensitivityText:self.decibelSensitivity];
        [section2 addObject:@{kTitle: @"声音侦测灵敏度", kValue: text, kAction: @"decibelSensitivityAction", kArrow: @"1"}];
    }
    if (section2.count > 0) {
        [dataSource addObject:@{kTitle: @"声音侦测", kValue: section2.copy}];
    }
    
    NSMutableArray *section3 = [NSMutableArray new];
    if ([self.dpManager isSurpportDP:TuyaSmartCameraSDCardStatusDPName]) {
        NSString *text = [self sdCardStatusText:self.sdCardStatus];
        [section3 addObject:@{kTitle: @"储存卡", kValue: text, kAction: @"sdCardAction", kArrow: @"1"}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraSDCardRecordDPName]) {
        [section3 addObject:@{kTitle: @"本地录像", kValue: @(self.sdRecordOn), kAction: @"sdRecordAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraRecordModeDPName]) {
        NSString *text = [self recordModeText:self.recordMode];
        [section3 addObject:@{kTitle: @"录像模式", kValue: text, kAction: @"recordModeAction", kArrow: @"1"}];
    }
    if (section3.count > 0) {
        [dataSource addObject:@{kTitle: @"存储卡", kValue: section3.copy}];
    }
    
    NSMutableArray *section4 = [NSMutableArray new];
    if ([self.dpManager isSurpportDP:TuyaSmartCameraWirelessBatteryLockDPName]) {
        [section4 addObject:@{kTitle: @"电池锁", kValue: @(self.batteryLockOn), kAction: @"batteryLockAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraWirelessPowerModeDPName]) {
        NSString *text = [self powerModeText:self.powerMode];
        [section4 addObject:@{kTitle: @"供电方式", kValue: text}];
    }
    
    if ([self.dpManager isSurpportDP:TuyaSmartCameraWirelessElectricityDPName]) {
        NSString *text = [self electricityText];
        [section4 addObject:@{kTitle: @"电量", kValue: text}];
    }
    if (section4.count > 0) {
        [dataSource addObject:@{kTitle: @"电池设备", kValue: section4.copy}];
    }
    self.dataSource = [dataSource copy];
    [self.tableView reloadData];
}

- (void)indicatorAction:(UISwitch *)switchButton {
    WEAKSELF_AT
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraBasicIndicatorDPName success:^(id result) {
        weakSelf_AT.indicatorOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf_AT reloadData];
    }];
}

- (void)flipAction:(UISwitch *)switchButton {
    WEAKSELF_AT
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraBasicFlipDPName success:^(id result) {
        weakSelf_AT.flipOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf_AT reloadData];
    }];
}

- (void)osdAction:(UISwitch *)switchButton {
    WEAKSELF_AT
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraBasicOSDDPName success:^(id result) {
        weakSelf_AT.osdOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf_AT reloadData];
    }];
}

- (void)privateAction:(UISwitch *)switchButton {
    WEAKSELF_AT
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraBasicPrivateDPName success:^(id result) {
        weakSelf_AT.privateOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf_AT reloadData];
    }];
}

- (void)nightvisionAction {
    NSArray *options = @[@{kTitle: [self nightvisionText:TuyaSmartCameraNightvisionAuto],
                           kValue: TuyaSmartCameraNightvisionAuto},
                         @{kTitle: [self nightvisionText:TuyaSmartCameraNightvisionOn],
                           kValue: TuyaSmartCameraNightvisionOn},
                         @{kTitle: [self nightvisionText:TuyaSmartCameraNightvisionOff],
                           kValue: TuyaSmartCameraNightvisionOff}];
    WEAKSELF_AT
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraBasicNightvisionDPName success:^(id result) {
            weakSelf_AT.nightvisionState = result;
            [weakSelf_AT reloadData];
        } failure:^(NSError *error) {
            
        }];
    }];
}

- (void)pirAction {
    NSArray *options = @[@{kTitle: [self pirText:TuyaSmartCameraPIRStateHigh],
                           kValue: TuyaSmartCameraPIRStateHigh},
                         @{kTitle: [self pirText:TuyaSmartCameraPIRStateMedium],
                           kValue: TuyaSmartCameraPIRStateMedium},
                         @{kTitle: [self pirText:TuyaSmartCameraPIRStateLow],
                           kValue: TuyaSmartCameraPIRStateLow},
                         @{kTitle: [self pirText:TuyaSmartCameraPIRStateOff],
                           kValue: TuyaSmartCameraPIRStateOff}];
    WEAKSELF_AT
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraBasicPIRDPName success:^(id result) {
            weakSelf_AT.pirState = result;
            [weakSelf_AT reloadData];
        } failure:^(NSError *error) {
            
        }];
    }];
}

- (void)motionDetectAction:(UISwitch *)switchButton {
    WEAKSELF_AT
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraMotionDetectDPName success:^(id result) {
        weakSelf_AT.motionDetectOn = switchButton.on;
        [weakSelf_AT reloadData];
    } failure:^(NSError *error) {
        [weakSelf_AT reloadData];
    }];
}

- (void)motionSensitivityAction {
    NSArray *options = @[@{kTitle: [self motionSensitivityText:TuyaSmartCameraMotionHigh],
                           kValue: TuyaSmartCameraMotionHigh},
                         @{kTitle: [self motionSensitivityText:TuyaSmartCameraMotionMedium],
                           kValue: TuyaSmartCameraMotionMedium},
                         @{kTitle: [self motionSensitivityText:TuyaSmartCameraMotionLow],
                           kValue: TuyaSmartCameraMotionLow}];
    WEAKSELF_AT
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraMotionSensitivityDPName success:^(id result) {
            weakSelf_AT.motionSensitivity = result;
            [weakSelf_AT reloadData];
        } failure:^(NSError *error) {
            
        }];
    }];
}

- (void)decibelDetectAction:(UISwitch *)switchButton {
    WEAKSELF_AT
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraDecibelDetectDPName success:^(id result) {
        weakSelf_AT.decibelDetectOn = switchButton.on;
        [weakSelf_AT reloadData];
    } failure:^(NSError *error) {
        [weakSelf_AT reloadData];
    }];
}

- (void)decibelSensitivityAction {
    NSArray *options = @[@{kTitle: [self decibelSensitivityText:TuyaSmartCameraDecibelHigh],
                           kValue: TuyaSmartCameraDecibelHigh},
                         @{kTitle: [self decibelSensitivityText:TuyaSmartCameraDecibelLow],
                           kValue: TuyaSmartCameraDecibelLow}];
    WEAKSELF_AT
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraDecibelSensitivityDPName success:^(id result) {
            weakSelf_AT.decibelSensitivity = result;
            [weakSelf_AT reloadData];
        } failure:^(NSError *error) {
            
        }];
    }];
}

- (void)sdCardAction {
    TuyaSmartSDCardViewController *vc = [TuyaSmartSDCardViewController new];
    vc.dpManager = self.dpManager;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)sdRecordAction:(UISwitch *)switchButton {
    WEAKSELF_AT
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraSDCardRecordDPName success:^(id result) {
        weakSelf_AT.sdRecordOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf_AT reloadData];
    }];
}

- (void)recordModeAction {
    NSArray *options = @[@{kTitle: [self recordModeText:TuyaSmartCameraRecordModeEvent],
                           kValue: TuyaSmartCameraRecordModeEvent},
                         @{kTitle: [self recordModeText:TuyaSmartCameraRecordModeAlways],
                           kValue: TuyaSmartCameraRecordModeAlways}];
    WEAKSELF_AT
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraRecordModeDPName success:^(id result) {
            weakSelf_AT.recordMode = result;
            [weakSelf_AT reloadData];
        } failure:^(NSError *error) {
            
        }];
    }];
}

- (void)batteryLockAction:(UISwitch *)switchButton {
    WEAKSELF_AT
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraWirelessBatteryLockDPName success:^(id result) {
        weakSelf_AT.batteryLockOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf_AT reloadData];
    }];
}

- (NSString *)nightvisionText:(TuyaSmartCameraNightvision)state {
    if ([state isEqualToString:TuyaSmartCameraNightvisionAuto]) {
        return @"自动";
    }
    if ([state isEqualToString:TuyaSmartCameraNightvisionOn]) {
        return @"开";
    }
    return @"关";
}

- (NSString *)pirText:(TuyaSmartCaemraPIR)state {
    if ([state isEqualToString:TuyaSmartCameraPIRStateLow]) {
        return @"低灵敏度";
    }
    if ([state isEqualToString:TuyaSmartCameraPIRStateMedium]) {
        return @"中灵敏度";
    }
    if ([state isEqualToString:TuyaSmartCameraPIRStateHigh]) {
        return @"高灵敏度";
    }
    return @"关闭";
}

- (NSString *)motionSensitivityText:(TuyaSmartCameraMotion)sensitivity {
    if ([sensitivity isEqualToString:TuyaSmartCameraMotionLow]) {
        return @"低灵敏度";
    }
    if ([sensitivity isEqualToString:TuyaSmartCameraMotionMedium]) {
        return @"中灵敏度";
    }
    if ([sensitivity isEqualToString:TuyaSmartCameraMotionHigh]) {
        return @"高灵敏度";
    }
    return @"";
}

- (NSString *)decibelSensitivityText:(TuyaSmartCameraDecibel)sensitivity {
    if ([sensitivity isEqualToString:TuyaSmartCameraDecibelLow]) {
        return @"低灵敏度";
    }
    if ([sensitivity isEqualToString:TuyaSmartCameraDecibelHigh]) {
        return @"高灵敏度";
    }
    return @"";
}

- (NSString *)sdCardStatusText:(TuyaSmartCameraSDCardStatus)status {
    switch (status) {
        case TuyaSmartCameraSDCardStatusNormal:
            return @"正常";
        case TuyaSmartCameraSDCardStatusException:
            return @"异常";
        case TuyaSmartCameraSDCardStatusMemoryLow:
            return @"容量不足";
        case TuyaSmartCameraSDCardStatusFormatting:
            return @"正在格式化";
        default:
            return @"无";
    }
}

- (NSString *)recordModeText:(TuyaSmartCameraRecordMode)mode {
    if ([mode isEqualToString:TuyaSmartCameraRecordModeEvent]) {
        return @"事件录像";
    }
    return @"连续录像";
}

- (NSString *)powerModeText:(TuyaSmartCameraPowerMode)mode {
    if ([mode isEqualToString:TuyaSmartCameraPowerModePlug]) {
        return @"插电";
    }
    return @"电池";
}

- (NSString *)electricityText {
    return [NSString stringWithFormat:@"%@%%", @(self.electricity)];
}

- (void)showActionSheet:(NSArray *)options selectedHandler:(void(^)(id result))handler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    [options enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:[obj objectForKey:kTitle] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            if (handler) {
                handler([obj objectForKey:kValue]);
            }
        }];
        [alert addAction:action];
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - dpmanagerobserver

- (void)cameraDPDidUpdate:(TuyaSmartCameraDPManager *)manager dps:(NSDictionary *)dpsData {
    if ([dpsData objectForKey:TuyaSmartCameraWirelessElectricityDPName]) {
        self.electricity = [[dpsData objectForKey:TuyaSmartCameraWirelessElectricityDPName] integerValue];
        [self reloadData];
    }
}

#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.dataSource objectAtIndex:section] objectForKey:kTitle];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.dataSource objectAtIndex:section] objectForKey:kValue] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [[[self.dataSource objectAtIndex:indexPath.section] valueForKey:kValue] objectAtIndex:indexPath.row];
    if ([data objectForKey:kSwitch]) {
        TuyaSmartSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        BOOL value = [[data objectForKey:kValue] boolValue];
        SEL action = NSSelectorFromString([data objectForKey:kAction]);
        [cell setValueChangedTarget:self selector:action value:value];
        cell.textLabel.text = [data objectForKey:kTitle];
        return cell;
    }else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"defaultCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"defaultCell"];
        }
        cell.textLabel.text = [data objectForKey:kTitle];
        cell.detailTextLabel.text = [data objectForKey:kValue];
        if ([data objectForKey:kArrow]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [[[self.dataSource objectAtIndex:indexPath.section] objectForKey:kValue] objectAtIndex:indexPath.row];
    if (![data objectForKey:kSwitch]) {
        NSString *action = [data objectForKey:kAction];
        if (action) {
            SEL selector = NSSelectorFromString(action);
            [self performSelector:selector withObject:nil afterDelay:0];
        }
    }
}

@end
