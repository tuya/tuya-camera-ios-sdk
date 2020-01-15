//
//  TuyaSmartActivatorViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/7/8.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TYQRCodeAddDeviceViewController.h"
#import "TYAddDeviceUtils.h"
#import <Masonry/Masonry.h>
#import <TuyaSmartActivatorKit/TuyaSmartActivatorKit.h>
#import "TYSmartHomeManager.h"

const NSInteger _timeLeft = 100;
static NSInteger _timeout = _timeLeft;

@interface TYQRCodeAddDeviceViewController ()<TuyaSmartActivatorDelegate>

@property (nonatomic, strong) UITextField *ssidField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextView *console;

@property (nonatomic, strong) UIImageView *qrCodeView;

@property (nonatomic, strong) UIButton *startButton;

@property (nonatomic, strong) NSString *token;

@property (nonatomic, strong) NSString *ssid;

@property (nonatomic, strong) NSString *pwd;

@end

@implementation TYQRCodeAddDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initView];
    [TuyaSmartActivator sharedInstance].delegate = self;
    self.topBarView.leftItem = self.leftBackItem;
}

- (NSString *)titleForCenterItem {
    return @"二维码配网";
}

- (void)initView {
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.topBarView.leftItem = self.leftBackItem;
    self.centerTitleItem.title = @"Add device QRCode";
    self.topBarView.centerItem = self.centerTitleItem;
    
    CGFloat currentY = self.topBarView.height;
    currentY += 10;
    
    //first line.
    CGFloat labelWidth = 75;
    CGFloat textFieldWidth = APP_SCREEN_WIDTH - labelWidth - 30;
    CGFloat labelHeight = 44;
    
    UILabel *ssidKeyLabel = [sharedAddDeviceUtils() keyLabel];
    ssidKeyLabel.text = @"ssid:";
    ssidKeyLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:ssidKeyLabel];
    
    self.ssidField = [sharedAddDeviceUtils() textField];
    self.ssidField.placeholder = @"Input your wifi ssid";
    self.ssidField.frame = CGRectMake(labelWidth + 20, currentY, textFieldWidth, labelHeight);
    [self.view addSubview:self.ssidField];
    currentY += labelHeight;
    NSString *ssid = [TuyaSmartActivator currentWifiSSID];
    if (ssid.length) {
        self.ssidField.text = ssid;
    }
    //second line.
    currentY += 10;
    UILabel *passwordKeyLabel = [sharedAddDeviceUtils() keyLabel];
    passwordKeyLabel.text = @"password:";
    passwordKeyLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:passwordKeyLabel];
    
    self.passwordField = [sharedAddDeviceUtils() textField];
    self.passwordField.placeholder = @"password of wifi";
    self.passwordField.frame = CGRectMake(labelWidth + 20, currentY, textFieldWidth, labelHeight);
    [self.view addSubview:self.passwordField];
    currentY += labelHeight;
    
    //third line.
    currentY += 10;
    UIButton *qrModeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    qrModeButton.layer.cornerRadius = 5;
    qrModeButton.frame = CGRectMake(10, currentY, APP_SCREEN_WIDTH - 20, labelHeight);
    [qrModeButton setTitle:@"Add device in EZ mode" forState:UIControlStateNormal];
    qrModeButton.backgroundColor = UIColor.orangeColor;
    [qrModeButton addTarget:self action:@selector(addDeviceWithQRMode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:qrModeButton];
    currentY += labelHeight;
    
    //forth line.
    currentY += 10;
    UILabel *titleLabel = [sharedAddDeviceUtils() keyLabel];
    titleLabel.text = @"console:";
    titleLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:titleLabel];
    currentY += labelHeight;
    
    //fifth line.
    self.console = [UITextView new];
    self.console.frame = CGRectMake(10, currentY, APP_SCREEN_WIDTH - 20, 220);
    self.console.layer.borderColor = UIColor.blackColor.CGColor;
    self.console.layer.borderWidth = 1;
    [self.view addSubview:self.console];
    self.console.editable = NO;
    self.console.layoutManager.allowsNonContiguousLayout = NO;
    self.console.backgroundColor = HEXCOLOR(0xededed);
    currentY += self.console.height;
    
    //final line
    currentY += 10;
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.layer.cornerRadius = 5;
    cancelButton.frame = CGRectMake(10, currentY, APP_SCREEN_WIDTH - 20, labelHeight);
    [cancelButton setTitle:@"Stop config wiFi" forState:UIControlStateNormal];
    cancelButton.backgroundColor = UIColor.orangeColor;
    [cancelButton addTarget:self action:@selector(stopConfigWiFi) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
    currentY += labelHeight;
    
    [self.view addSubview:self.qrCodeView];
    self.qrCodeView.frame = self.view.bounds;
    [self.view addSubview:self.startButton];
    self.startButton.frame = CGRectMake(10, currentY + 30 , APP_SCREEN_WIDTH - 20, labelHeight);
    [self.startButton addTarget:self action:@selector(startAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view bringSubviewToFront:self.topBarView];
}

- (void)countDown {
    _timeout --;
    
    if (_timeout) {
        [self performSelector:@selector(countDown) withObject:nil afterDelay:1];
        [self appendConsoleLog:[NSString stringWithFormat:@"%@: %@ seconds left before timeout.",NSStringFromSelector(_cmd),@(_timeout)]];
    } else {
        _timeout = _timeLeft;
    }
}

- (void)commitQRModeActionWithToken:(NSString *)token {
    self.token = token;
    self.ssid = self.ssidField.text;
    self.pwd = self.passwordField.text ? self.passwordField.text : @"";
    
    NSDictionary *info = @{
                           @"s": self.ssid,
                           @"p": self.pwd,
                           @"t": token
                           };
    self.qrCodeView.image = [TYAddDeviceUtils qrCodeWithString:[info tysdk_JSONString] width:self.view.frame.size.width - 44];
    self.qrCodeView.hidden = NO;
    self.startButton.hidden = NO;
}

- (void)stopConfigWiFi {
    [[TuyaSmartActivator sharedInstance] stopConfigWiFi];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(countDown) object:nil];
    _timeout = _timeLeft;
    [self hideProgressView];
    [self appendConsoleLog:@"Activator action canceled"];
}

- (void)addDeviceWithQRMode {
    
    [self.view endEditing:YES];
    if (!self.ssidField.text.length) {
        [sharedAddDeviceUtils() alertMessage:@"ssid can't be nil"];
        return;
    }
    //If already in EZ mode progress, do nothing.
    if (_timeout < _timeLeft) {
        [self appendConsoleLog:@"Activitor is still in progress, please wait..."];
        return;
    }
    //Get token from server with current homeId before commit activit progress.
    __block NSString *info = [NSString stringWithFormat:@"%@: start add device in EZMode",NSStringFromSelector(_cmd)];
    [self appendConsoleLog:info];
    info = [NSString stringWithFormat:@"%@: start get token",NSStringFromSelector(_cmd)];
    [self appendConsoleLog:info];
    WEAKSELF_AT
    long long homeId = [TYSmartHomeManager sharedInstance].currentHome.homeModel.homeId;
    [[TuyaSmartActivator sharedInstance] getTokenWithHomeId:homeId success:^(NSString *token) {
        
        info = [NSString stringWithFormat:@"%@: token fetched, token is %@",NSStringFromSelector(_cmd),token];
        [weakSelf_AT appendConsoleLog:info];
        
        [weakSelf_AT commitQRModeActionWithToken:token];
    } failure:^(NSError *error) {
        
        info = [NSString stringWithFormat:@"%@: token fetch failed, error message is %@",NSStringFromSelector(_cmd),error.localizedDescription];
        [weakSelf_AT appendConsoleLog:info];
    }];
}

- (void)appendConsoleLog:(NSString *)logString {
    
    if (!logString) {
        logString = [NSString stringWithFormat:@"%@ : param error",NSStringFromSelector(_cmd)];
    }
    NSString *result = self.console.text?:@"";
    result = [[result stringByAppendingString:logString] stringByAppendingString:@"\n"];
    self.console.text = result;
    [self.console scrollRangeToVisible:NSMakeRange(result.length, 1)];
}


#pragma mark - TuyaSmartActivatorDelegate

- (void)activator:(TuyaSmartActivator *)activator didReceiveDevice:(TuyaSmartDeviceModel *)deviceModel error:(NSError *)error {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(countDown) object:nil];
    _timeout = _timeLeft;
    [self hideProgressView];
    
    NSString *info = [NSString stringWithFormat:@"%@: Finished!", NSStringFromSelector(_cmd)];
    [self appendConsoleLog:info];
    if (error) {
        info = [NSString stringWithFormat:@"%@: Error-%@!", NSStringFromSelector(_cmd), error.localizedDescription];
        [self appendConsoleLog:info];
    } else {
        info = [NSString stringWithFormat:@"%@: Success-You've added device %@ successfully!", NSStringFromSelector(_cmd), deviceModel.name];
        [self appendConsoleLog:info];
    }
}


- (void)startAction {
    [TuyaSmartActivator sharedInstance].delegate = self;
    [[TuyaSmartActivator sharedInstance] startConfigWiFi:TYActivatorModeQRCode ssid:self.ssid password:self.pwd token:self.token timeout:_timeout];
    [self countDown];
    self.qrCodeView.hidden = YES;
    self.startButton.hidden = YES;
}


- (UIImageView *)qrCodeView {
    if (!_qrCodeView) {
        _qrCodeView = [[UIImageView alloc] init];
        _qrCodeView.contentMode = UIViewContentModeCenter;
        _qrCodeView.hidden = YES;
        _qrCodeView.backgroundColor = [UIColor whiteColor];
    }
    return _qrCodeView;
}

- (UIButton *)startButton {
    if (!_startButton) {
        _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startButton setTitle:@"Heard a Prompt" forState:UIControlStateNormal];
        _startButton.layer.cornerRadius = 5;
        _startButton.backgroundColor = [UIColor orangeColor];
        _startButton.hidden = YES;
    }
    return _startButton;
}

@end
