//
//  TuyaSmartCameraViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/13.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartCameraViewController.h"
#import "TuyaSmartCameraControlView.h"
#import "TuyaSmartCameraDefault.h"
#import "TYPermissionUtil.h"
#import "TuyaSmartCameraPlaybackViewController.h"
#import "TuyaSmartCameraSettingViewController.h"

#define TopBarHeight 88
#define VideoViewWidth [UIScreen mainScreen].bounds.size.width
#define VideoViewHeight ([UIScreen mainScreen].bounds.size.width / 16 * 9)

#define kControlTalk        @"talk"
#define kControlRecord      @"record"
#define kControlPhoto       @"photo"
#define kControlPlayback    @"playback"

@interface TuyaSmartCameraViewController ()<TuyaSmartCameraObserver, TuyaSmartCameraControlViewDelegate, TuyaSmartCameraDPObserver>

@property (nonatomic, strong) NSString *devId;

@property (nonatomic, strong) TuyaSmartCameraDefault *camera;

@property (nonatomic, strong) UIView *videoContainer;

@property (nonatomic, strong) TuyaSmartCameraControlView *controlView;

@property (nonatomic, strong) UIButton *soundButton;

@property (nonatomic, strong) UIButton *hdButton;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, strong) UIButton *retryButton;

@end

@implementation TuyaSmartCameraViewController

- (void)dealloc {
    [self.camera disConnect];
}

- (instancetype)initWithDeviceId:(NSString *)devId {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _devId = devId;
        _camera = [[TuyaSmartCameraDefault alloc] initWithDeviceId:devId];
        [_camera.dpManager addObserver:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.camera.device.deviceModel.name;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.videoContainer];
    [self.view addSubview:self.indicatorView];
    [self.view addSubview:self.stateLabel];
    [self.view addSubview:self.retryButton];
    [self.view addSubview:self.controlView];
    [self.view addSubview:self.soundButton];
    [self.view addSubview:self.hdButton];
    
    [self.retryButton addTarget:self action:@selector(retryAction) forControlEvents:UIControlEventTouchUpInside];
    [self.soundButton addTarget:self action:@selector(soundAction) forControlEvents:UIControlEventTouchUpInside];
    [self.hdButton addTarget:self action:@selector(hdAction) forControlEvents:UIControlEventTouchUpInside];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(settingAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.camera stopPreview];
    [self.camera removeObserver:self];
    [self.camera.dpManager removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.camera addObserVer:self];
    
    [self retryAction];
}

- (void)didEnterBackground {
    [self.camera stopPreview];
}

- (void)willEnterForeground {
    [self retryAction];
}

- (void)showLoadingWithTitle:(NSString *)title {
    self.indicatorView.hidden = NO;
    [self.indicatorView startAnimating];
    self.stateLabel.hidden = NO;
    self.stateLabel.text = title;
}

- (void)stopLoading {
    [self.indicatorView stopAnimating];
    self.indicatorView.hidden = YES;
    self.stateLabel.hidden = YES;
}

- (void)cameraDPDidUpdate:(TuyaSmartCameraDPManager *)manager dps:(NSDictionary *)dpsData {
    if ([[dpsData objectForKey:TuyaSmartCameraWirelessAwakeDPName] boolValue]) {
        [self retryAction];
    }
}

#pragma mark - Action

- (void)settingAction {
    TuyaSmartCameraSettingViewController *settingVC = [TuyaSmartCameraSettingViewController new];
    settingVC.dpManager = self.camera.dpManager;
    [self.navigationController pushViewController:settingVC animated:YES];
}

- (void)retryAction {
    [self.controlView disableAllControl];
    if (!self.camera.device.deviceModel.isOnline) {
        self.stateLabel.hidden = NO;
        self.stateLabel.text = @"device is offline";
        return;
    }
    if ([self isDoorbell]) {
        BOOL isAwaking = [[self.camera.dpManager valueForDP:TuyaSmartCameraWirelessAwakeDPName] boolValue];
        if (isAwaking) {
            if (self.camera.isConnected) {
                [self.videoContainer addSubview:self.camera.videoView];
                self.camera.videoView.frame = self.videoContainer.bounds;
                [self.camera startPreview];
            }else {
                [self.camera connect];
            }
        }else {
            [self.camera.device awakeDeviceWithSuccess:nil failure:nil];
        }
    }else {
        if (self.camera.isConnected) {
            [self.videoContainer addSubview:self.camera.videoView];
            self.camera.videoView.frame = self.videoContainer.bounds;
            [self.camera startPreview];
        }else {
            [self.camera connect];
        }
    }
    [self showLoadingWithTitle:@"loading..."];
    self.retryButton.hidden = YES;
}

- (BOOL)isDoorbell {
    return [self.camera.dpManager isSupportDP:TuyaSmartCameraWirelessAwakeDPName];
}

- (void)soundAction {
    self.camera.muted = !self.camera.isMuted;
}

- (void)hdAction {
    self.camera.HD = !self.camera.isHD;
}

- (void)talkAction {
    if ([TYPermissionUtil microNotDetermined]) {
        [TYPermissionUtil requestAccessForMicro:^(BOOL result) {
            if (result) {
                [self.camera startTalk];
            }
        }];
    }else if ([TYPermissionUtil microDenied]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Micro permission denied" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }else {
        [self.camera startTalk];
    }
}

- (void)recordAction {
    if (self.camera.isRecording) {
        [self.camera stopRecord];
    }else {
        [self.camera startRecord];
    }
}

- (void)photoAction {
    if ([self.camera snapShoot]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Screenshot did saved to photo library" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


#pragma mark - TuyaSmartCameraObserver

- (void)cameraDidConnected:(TuyaSmartCameraDefault *)camera {
    [self.videoContainer addSubview:self.camera.videoView];
    self.camera.videoView.frame = self.videoContainer.bounds;
    [self.camera startPreview];
}

- (void)cameraDidDisconnected:(TuyaSmartCameraDefault *)camera {
    [self.controlView disableAllControl];
    self.retryButton.hidden = NO;
}

- (void)cameraDidStartPreview:(TuyaSmartCameraDefault *)camera {
    [self.controlView enableAllControl];
    [self stopLoading];
}

- (void)cameraDidStartTalk:(TuyaSmartCameraDefault *)camera {
    [self.controlView selectedControl:kControlTalk];
}

- (void)cameraDidStopTalk:(TuyaSmartCameraDefault *)camera {
    [self.controlView deselectedControl:kControlTalk];
}

- (void)cameraDidStartRecording:(TuyaSmartCameraDefault *)camera {
    [self.controlView selectedControl:kControlRecord];
}

- (void)cameraDidStopRecording:(TuyaSmartCameraDefault *)camera {
    [self.controlView deselectedControl:kControlRecord];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"video did saved to photo library" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)camera:(TuyaSmartCameraDefault *)camera muteStateDidChanged:(BOOL)isMuted {
    NSString *imageName = @"ty_camera_soundOn_icon";
    if (isMuted) {
        imageName = @"ty_camera_soundOff_icon";
    }
    [self.soundButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (void)camera:(TuyaSmartCameraDefault *)camera definitionStateDidChanged:(BOOL)isHD {
    NSString *imageName = @"ty_camera_control_sd_normal";
    if (isHD) {
        imageName = @"ty_camera_control_hd_normal";
    }
    [self.hdButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (void)camera:(TuyaSmartCameraDefault *)camera didOccurredError:(TYCameraErrorCode)errCode {
    NSString *errString = nil;
    switch (errCode) {
        case TY_ERROR_CONNECT_FAILED:
        case TY_ERROR_START_PREVIEW_FAILED:
            [self stopLoading];
            self.retryButton.hidden = NO;
            break;
        case TY_ERROR_START_TALK_FAILED:
            errString = @"start talk failed";
            break;
        case TY_ERROR_RECORD_FAILED:
            errString = @"recording falied";
            break;
        case TY_ERROR_ENABLE_MUTE_FAILED:
            errString = @"enable mute failed";
            break;
        case TY_ERROR_ENABLE_HD_FAILED:
            errString = @"change definition failed";
            break;
        default:
            break;
    }
    
    if (errString) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:errString preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - TuyaSmartCameraControlViewDelegate

- (void)controlView:(TuyaSmartCameraControlView *)controlView didSelectedControl:(NSString *)identifier {
    if ([identifier isEqualToString:kControlTalk]) {
        [self talkAction];
        return;
    }
    if ([identifier isEqualToString:kControlPlayback]) {
        TuyaSmartCameraPlaybackViewController *vc = [TuyaSmartCameraPlaybackViewController new];
        vc.camera = self.camera;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    BOOL needPhotoPermission = [identifier isEqualToString:kControlPhoto] || [identifier isEqualToString:kControlRecord];
    if (needPhotoPermission) {
        if ([TYPermissionUtil isPhotoLibraryNotDetermined]) {
            [TYPermissionUtil requestPhotoPermission:^(BOOL result) {
                if (result) {
                    if ([identifier isEqualToString:kControlRecord]) {
                        [self recordAction];
                    } else if ([identifier isEqualToString:kControlPhoto]) {
                        [self photoAction];
                    }
                }
            }];
        }else if ([TYPermissionUtil isPhotoLibraryDenied]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Photo permission denied" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
        }else {
            if ([identifier isEqualToString:kControlRecord]) {
                [self recordAction];
            } else if ([identifier isEqualToString:kControlPhoto]) {
                [self photoAction];
            }
        }
    }
}

#pragma mark - Accessor

- (UIView *)videoContainer {
    if (!_videoContainer) {
        _videoContainer = [[UIView alloc] initWithFrame:CGRectMake(0, TopBarHeight, VideoViewWidth, VideoViewHeight)];
        _videoContainer.backgroundColor = [UIColor blackColor];
    }
    return _videoContainer;
}

- (NSArray *)controlDatas {
    return @[@{
                 @"image": @"ty_camera_mic_icon",
                 @"title": @"talk",
                 @"identifier": kControlTalk
                 },
             @{
                 @"image": @"ty_camera_rec_icon",
                 @"title": @"record",
                 @"identifier": kControlRecord
                 },
             @{
                 @"image": @"ty_camera_photo_icon",
                 @"title": @"photo",
                 @"identifier": kControlPhoto
                 },
             @{
                 @"image": @"ty_camera_playback_icon",
                 @"title": @"playback",
                 @"identifier": kControlPlayback
                 }
             ];
}

- (TuyaSmartCameraControlView *)controlView {
    if (!_controlView) {
        CGFloat top = VideoViewHeight + TopBarHeight;
        CGFloat width = self.view.frame.size.width;
        CGFloat height = self.view.frame.size.height - top;
        _controlView = [[TuyaSmartCameraControlView alloc] initWithFrame:CGRectMake(0, top, width, height)];
        _controlView.sourceData = [self controlDatas];
        _controlView.delegate = self;
    }
    return _controlView;
}

- (UIButton *)soundButton {
    if (!_soundButton) {
        _soundButton = [[UIButton alloc] initWithFrame:CGRectMake(8, TopBarHeight + VideoViewHeight - 50, 44, 44)];
        [_soundButton setImage:[UIImage imageNamed:@"ty_camera_soundOff_icon"] forState:UIControlStateNormal];
    }
    return _soundButton;
}

- (UIButton *)hdButton {
    if (!_hdButton) {
        _hdButton = [[UIButton alloc] initWithFrame:CGRectMake(60, TopBarHeight + VideoViewHeight - 50, 44, 44)];
        [_hdButton setImage:[UIImage imageNamed:@"ty_camera_control_sd_normal"] forState:UIControlStateNormal];
    }
    return _hdButton;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        CGPoint center = self.videoContainer.center;
        center.y -= 20;
        _indicatorView.center = center;
        _indicatorView.hidden = YES;
    }
    return _indicatorView;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.indicatorView.frame) + 8, VideoViewWidth, 20)];
        _stateLabel.textAlignment = NSTextAlignmentCenter;
        _stateLabel.textColor = [UIColor whiteColor];
        _stateLabel.hidden = YES;
    }
    return _stateLabel;
}

- (UIButton *)retryButton {
    if (!_retryButton) {
        _retryButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, VideoViewWidth, 40)];
        _retryButton.center = self.videoContainer.center;
        [_retryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_retryButton setTitle:@"connect failed, click retry" forState:UIControlStateNormal];
        _retryButton.hidden = YES;
    }
    return _retryButton;
}

@end
