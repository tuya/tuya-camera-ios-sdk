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

@interface TuyaSmartCameraSettingViewController ()<TuyaSmartCameraDPObserver, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, assign) BOOL indicatorOn;

@property (nonatomic, assign) BOOL flipOn;

@property (nonatomic, assign) BOOL osdOn;

@property (nonatomic, assign) BOOL privateOn;

@property (nonatomic, strong) TuyaSmartCameraNightvision nightvisionState;

@property (nonatomic, strong) TuyaSmartCameraPIR pirState;

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

@property (nonatomic, strong) TuyaSmartDevice *device;

@end

@implementation TuyaSmartCameraSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    [self.dpManager addObserver:self];
    [self.tableView registerClass:[TuyaSmartSwitchCell class] forCellReuseIdentifier:@"switchCell"];
    [self getDeviceInfo];
    [self setupTableFooter];
    self.topBarView.leftItem = self.leftBackItem;
}

- (NSString *)titleForCenterItem {
    return @"Setting";
}

- (void)setupTableFooter {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 50)];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [button setTitle:@"remove device" forState:UIControlStateNormal];
    [footerView addSubview:button];
    self.tableView.tableFooterView = footerView;
    [button addTarget:self action:@selector(removeAction) forControlEvents:UIControlEventTouchUpInside];
}

- (void)removeAction {
    __weak typeof(self) weakSelf = self;
    [self.device remove:^{
        [weakSelf.navigationController popToRootViewControllerAnimated:YES];
    } failure:^(NSError *error) {
        NSLog(@"&&& remove device %@", error);
    }];
}

- (void)getDeviceInfo {
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicIndicatorDPName]) {
        self.indicatorOn = [[self.dpManager valueForDP:TuyaSmartCameraBasicIndicatorDPName] tysdk_toBool];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicFlipDPName]) {
        self.flipOn = [[self.dpManager valueForDP:TuyaSmartCameraBasicFlipDPName] tysdk_toBool];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicOSDDPName]) {
        self.osdOn = [[self.dpManager valueForDP:TuyaSmartCameraBasicOSDDPName] tysdk_toBool];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicPrivateDPName]) {
        self.privateOn = [[self.dpManager valueForDP:TuyaSmartCameraBasicPrivateDPName] tysdk_toBool];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicNightvisionDPName]) {
        self.nightvisionState = [[self.dpManager valueForDP:TuyaSmartCameraBasicNightvisionDPName] tysdk_toString];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicPIRDPName]) {
        self.pirState = [[self.dpManager valueForDP:TuyaSmartCameraBasicPIRDPName] tysdk_toString];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraMotionDetectDPName]) {
        self.motionDetectOn = [[self.dpManager valueForDP:TuyaSmartCameraMotionDetectDPName] tysdk_toBool];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraMotionSensitivityDPName]) {
        self.motionSensitivity = [[self.dpManager valueForDP:TuyaSmartCameraMotionSensitivityDPName] tysdk_toString];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraDecibelDetectDPName]) {
        self.decibelDetectOn = [[self.dpManager valueForDP:TuyaSmartCameraDecibelDetectDPName] tysdk_toBool];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraDecibelSensitivityDPName]) {
        self.decibelSensitivity = [[self.dpManager valueForDP:TuyaSmartCameraDecibelSensitivityDPName] tysdk_toString];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraSDCardStatusDPName]) {
        self.sdCardStatus = [[self.dpManager valueForDP:TuyaSmartCameraSDCardStatusDPName] tysdk_toInt];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraSDCardRecordDPName]) {
        self.sdRecordOn = [[self.dpManager valueForDP:TuyaSmartCameraSDCardRecordDPName] tysdk_toBool];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraRecordModeDPName]) {
        self.recordMode = [[self.dpManager valueForDP:TuyaSmartCameraRecordModeDPName] tysdk_toString];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraWirelessBatteryLockDPName]) {
        self.batteryLockOn = [[self.dpManager valueForDP:TuyaSmartCameraWirelessBatteryLockDPName] tysdk_toBool];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraWirelessPowerModeDPName]) {
        self.powerMode = [[self.dpManager valueForDP:TuyaSmartCameraWirelessPowerModeDPName] tysdk_toString];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraWirelessElectricityDPName]) {
        self.electricity = [[self.dpManager valueForDP:TuyaSmartCameraWirelessElectricityDPName] tysdk_toInt];
    }
    [self reloadData];
}

- (void)reloadData {
    NSMutableArray *dataSource = [NSMutableArray new];
    NSMutableArray *section0 = [NSMutableArray new];
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicIndicatorDPName]) {
        [section0 addObject:@{kTitle:@"指示灯", kValue: @(self.indicatorOn), kAction: @"indicatorAction:", kSwitch: @"1"}];
    }
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicFlipDPName]) {
        [section0 addObject:@{kTitle: @"画面翻转", kValue: @(self.flipOn), kAction: @"flipAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicOSDDPName]) {
        [section0 addObject:@{kTitle: @"时间水印", kValue: @(self.osdOn), kAction: @"osdAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicPrivateDPName]) {
        [section0 addObject:@{kTitle: @"隐私模式", kValue: @(self.privateOn), kAction: @"privateAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicNightvisionDPName]) {
        NSString *text = [self nightvisionText:self.nightvisionState];
        [section0 addObject:@{kTitle: @"红外夜视", kValue: text, kAction: @"nightvisionAction", kArrow: @"1"}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraBasicPIRDPName]) {
        NSString *text = [self pirText:self.pirState];
        [section0 addObject:@{kTitle: @"PIR", kValue: text, kAction: @"pirAction", kArrow: @"1"}];
    }
    
    if (section0.count > 0) {
        [dataSource addObject:@{kTitle:@"基础设置", kValue: section0.copy}];
    }
    
    NSMutableArray *section1 = [NSMutableArray new];
    if ([self.dpManager isSupportDP:TuyaSmartCameraMotionDetectDPName]) {
        [section1 addObject:@{kTitle: @"移动侦测", kValue: @(self.motionDetectOn), kAction: @"motionDetectAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraMotionSensitivityDPName] && self.motionDetectOn) {
        NSString *text = [self motionSensitivityText:self.motionSensitivity];
        [section1 addObject:@{kTitle: @"移动侦测灵敏度", kValue: text, kAction: @"motionSensitivityAction", kArrow: @"1"}];
    }
    if (section1.count > 0) {
        [dataSource addObject:@{kTitle: @"移动侦测", kValue: section1.copy}];
    }
    
    NSMutableArray *section2 = [NSMutableArray new];
    if ([self.dpManager isSupportDP:TuyaSmartCameraDecibelDetectDPName]) {
        [section2 addObject:@{kTitle: @"声音侦测", kValue: @(self.decibelDetectOn), kAction: @"decibelDetectAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraDecibelSensitivityDPName] && self.decibelDetectOn) {
        NSString *text = [self decibelSensitivityText:self.decibelSensitivity];
        [section2 addObject:@{kTitle: @"声音侦测灵敏度", kValue: text, kAction: @"decibelSensitivityAction", kArrow: @"1"}];
    }
    if (section2.count > 0) {
        [dataSource addObject:@{kTitle: @"声音侦测", kValue: section2.copy}];
    }
    
    NSMutableArray *section3 = [NSMutableArray new];
    if ([self.dpManager isSupportDP:TuyaSmartCameraSDCardStatusDPName]) {
        NSString *text = [self sdCardStatusText:self.sdCardStatus];
        [section3 addObject:@{kTitle: @"储存卡", kValue: text, kAction: @"sdCardAction", kArrow: @"1"}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraSDCardRecordDPName]) {
        [section3 addObject:@{kTitle: @"本地录像", kValue: @(self.sdRecordOn), kAction: @"sdRecordAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraRecordModeDPName]) {
        NSString *text = [self recordModeText:self.recordMode];
        [section3 addObject:@{kTitle: @"录像模式", kValue: text, kAction: @"recordModeAction", kArrow: @"1"}];
    }
    if (section3.count > 0) {
        [dataSource addObject:@{kTitle: @"存储卡", kValue: section3.copy}];
    }
    
    NSMutableArray *section4 = [NSMutableArray new];
    if ([self.dpManager isSupportDP:TuyaSmartCameraWirelessBatteryLockDPName]) {
        [section4 addObject:@{kTitle: @"电池锁", kValue: @(self.batteryLockOn), kAction: @"batteryLockAction:", kSwitch: @"1"}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraWirelessPowerModeDPName]) {
        NSString *text = [self powerModeText:self.powerMode];
        [section4 addObject:@{kTitle: @"供电方式", kValue: text}];
    }
    
    if ([self.dpManager isSupportDP:TuyaSmartCameraWirelessElectricityDPName]) {
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
    __weak typeof(self) weakSelf = self;
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraBasicIndicatorDPName success:^(id result) {
        weakSelf.indicatorOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf reloadData];
    }];
}

- (void)flipAction:(UISwitch *)switchButton {
    __weak typeof(self) weakSelf = self;
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraBasicFlipDPName success:^(id result) {
        weakSelf.flipOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf reloadData];
    }];
}

- (void)osdAction:(UISwitch *)switchButton {
    __weak typeof(self) weakSelf = self;
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraBasicOSDDPName success:^(id result) {
        weakSelf.osdOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf reloadData];
    }];
}

- (void)privateAction:(UISwitch *)switchButton {
    __weak typeof(self) weakSelf = self;
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraBasicPrivateDPName success:^(id result) {
        weakSelf.privateOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf reloadData];
    }];
}

- (void)nightvisionAction {
    NSArray *options = @[@{kTitle: [self nightvisionText:TuyaSmartCameraNightvisionAuto],
                           kValue: TuyaSmartCameraNightvisionAuto},
                         @{kTitle: [self nightvisionText:TuyaSmartCameraNightvisionOn],
                           kValue: TuyaSmartCameraNightvisionOn},
                         @{kTitle: [self nightvisionText:TuyaSmartCameraNightvisionOff],
                           kValue: TuyaSmartCameraNightvisionOff}];
    __weak typeof(self) weakSelf = self;
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraBasicNightvisionDPName success:^(id result) {
            weakSelf.nightvisionState = result;
            [weakSelf reloadData];
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
    __weak typeof(self) weakSelf = self;
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraBasicPIRDPName success:^(id result) {
            weakSelf.pirState = result;
            [weakSelf reloadData];
        } failure:^(NSError *error) {
            
        }];
    }];
}

- (void)motionDetectAction:(UISwitch *)switchButton {
    __weak typeof(self) weakSelf = self;
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraMotionDetectDPName success:^(id result) {
        weakSelf.motionDetectOn = switchButton.on;
        [weakSelf reloadData];
    } failure:^(NSError *error) {
        [weakSelf reloadData];
    }];
}

- (void)motionSensitivityAction {
    NSArray *options = @[@{kTitle: [self motionSensitivityText:TuyaSmartCameraMotionHigh],
                           kValue: TuyaSmartCameraMotionHigh},
                         @{kTitle: [self motionSensitivityText:TuyaSmartCameraMotionMedium],
                           kValue: TuyaSmartCameraMotionMedium},
                         @{kTitle: [self motionSensitivityText:TuyaSmartCameraMotionLow],
                           kValue: TuyaSmartCameraMotionLow}];
    __weak typeof(self) weakSelf = self;
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraMotionSensitivityDPName success:^(id result) {
            weakSelf.motionSensitivity = result;
            [weakSelf reloadData];
        } failure:^(NSError *error) {
            
        }];
    }];
}

- (void)decibelDetectAction:(UISwitch *)switchButton {
    __weak typeof(self) weakSelf = self;
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraDecibelDetectDPName success:^(id result) {
        weakSelf.decibelDetectOn = switchButton.on;
        [weakSelf reloadData];
    } failure:^(NSError *error) {
        [weakSelf reloadData];
    }];
}

- (void)decibelSensitivityAction {
    NSArray *options = @[@{kTitle: [self decibelSensitivityText:TuyaSmartCameraDecibelHigh],
                           kValue: TuyaSmartCameraDecibelHigh},
                         @{kTitle: [self decibelSensitivityText:TuyaSmartCameraDecibelLow],
                           kValue: TuyaSmartCameraDecibelLow}];
    __weak typeof(self) weakSelf = self;
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraDecibelSensitivityDPName success:^(id result) {
            weakSelf.decibelSensitivity = result;
            [weakSelf reloadData];
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
    __weak typeof(self) weakSelf = self;
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraSDCardRecordDPName success:^(id result) {
        weakSelf.sdRecordOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf reloadData];
    }];
}

- (void)recordModeAction {
    NSArray *options = @[@{kTitle: [self recordModeText:TuyaSmartCameraRecordModeEvent],
                           kValue: TuyaSmartCameraRecordModeEvent},
                         @{kTitle: [self recordModeText:TuyaSmartCameraRecordModeAlways],
                           kValue: TuyaSmartCameraRecordModeAlways}];
    __weak typeof(self) weakSelf = self;
    [self showActionSheet:options selectedHandler:^(id result) {
        [self.dpManager setValue:result forDP:TuyaSmartCameraRecordModeDPName success:^(id result) {
            weakSelf.recordMode = result;
            [weakSelf reloadData];
        } failure:^(NSError *error) {
            
        }];
    }];
}

- (void)batteryLockAction:(UISwitch *)switchButton {
    __weak typeof(self) weakSelf = self;
    [self.dpManager setValue:@(switchButton.on) forDP:TuyaSmartCameraWirelessBatteryLockDPName success:^(id result) {
        weakSelf.batteryLockOn = switchButton.on;
    } failure:^(NSError *error) {
        [weakSelf reloadData];
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

- (NSString *)pirText:(TuyaSmartCameraPIR)state {
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
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

- (TuyaSmartDevice *)device {
    if (!_device) {
        _device = [TuyaSmartDevice deviceWithDeviceId:self.devId];
    }
    return _device;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, APP_TOP_BAR_HEIGHT, APP_SCREEN_WIDTH, APP_SCREEN_HEIGHT - APP_TOP_BAR_HEIGHT) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

@end
