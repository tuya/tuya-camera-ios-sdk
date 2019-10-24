//
//  TuyaSmartCameraViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/13.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartCameraViewController.h"
#import "TuyaSmartCameraControlView.h"
#import "TYPermissionUtil.h"
#import "TuyaSmartCameraPlaybackViewController.h"
#import "TuyaSmartCameraSettingViewController.h"
#import "TuyaSmartCamera.h"
#import "TYCameraCloudViewController.h"
#import "TYCameraMessageViewController.h"

#define TopBarHeight 88
#define VideoViewWidth [UIScreen mainScreen].bounds.size.width
#define VideoViewHeight ([UIScreen mainScreen].bounds.size.width / 16 * 9)

#define kControlTalk        @"talk"
#define kControlRecord      @"record"
#define kControlPhoto       @"photo"
#define kControlPlayback    @"playback"
#define kControlCloud       @"Cloud"
#define kControlMessage     @"message"

@interface TuyaSmartCameraViewController ()<TuyaSmartCameraObserver, TuyaSmartCameraControlViewDelegate, TuyaSmartCameraDPObserver>

@property (nonatomic, strong) NSString *devId;

@property (nonatomic, strong) TuyaSmartCamera *camera;

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
        _camera = [[TuyaSmartCamera alloc] initWithDeviceId:devId];
        [_camera.dpManager addObserver:self];
    }
    return self;
}

- (NSString *)titleForCenterItem {
    return self.camera.device.deviceModel.name;
}

- (NSString *)titleForRightItem {
    return @"Setting";
}

- (void)rightBtnAction {
    [self settingAction];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.camera.device.deviceModel.name;
    self.view.backgroundColor = [UIColor whiteColor];
    self.topBarView.leftItem = self.leftBackItem;
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.camera stopPreview];
    [self.camera removeObserver:self];
    [self.camera.dpManager removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.camera addObserver:self];
    
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
    settingVC.devId = self.devId;
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
            [self connectCamera:^(BOOL success) {
                if (success) {
                    [self startPreview];
                }else {
                    [self stopLoading];
                    self.retryButton.hidden = NO;
                }
            }];
        }else {
            [self.camera.device awakeDeviceWithSuccess:nil failure:nil];
        }
    }else {
        [self connectCamera:^(BOOL success) {
            if (success) {
                [self startPreview];
            }else {
                [self stopLoading];
                self.retryButton.hidden = NO;
            }
        }];
    }
    [self showLoadingWithTitle:@"loading..."];
    self.retryButton.hidden = YES;
}

- (void)connectCamera:(void(^)(BOOL success))complete {
    if (self.camera.isConnecting) return;
    if (self.camera.isConnected) {
        complete(YES);
        return;
    }
    [self.camera connect:^{
        complete(YES);
    } failure:^(NSError *error) {
        complete(NO);
    }];
}

- (BOOL)isDoorbell {
    return [self.camera.dpManager isSupportDP:TuyaSmartCameraWirelessAwakeDPName];
}

- (void)startPreview {
    [self.videoContainer addSubview:self.camera.videoView];
    self.camera.videoView.frame = self.videoContainer.bounds;
    [self.camera startPreview:^{
        [self.controlView enableAllControl];
        [self stopLoading];
    } failure:^(NSError *error) {
        [self stopLoading];
        self.retryButton.hidden = NO;
    }];
}

- (void)soundAction {
    [self.camera enableMute:!self.camera.isMuted success:^{
        NSLog(@"enable mute success");
    } failure:^(NSError *error) {
        [self showAlertWithMessage:@"enable mute faied" complete:nil];
    }];
}

- (void)hdAction {
    [self.camera enableHD:!self.camera.isHD success:^{
        NSLog(@"enable HD success");
    } failure:^(NSError *error) {
        [self showAlertWithMessage:@"enable hd failed" complete:nil];
    }];
}

- (void)talkAction {
    if ([TYPermissionUtil microNotDetermined]) {
        [TYPermissionUtil requestAccessForMicro:^(BOOL result) {
            if (result) {
                [self _talkAction];
            }
        }];
    }else if ([TYPermissionUtil microDenied]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Micro permission denied" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }else {
        [self _talkAction];
    }
}

- (void)_talkAction {
    if (self.camera.isTalking) {
        [self.camera stopTalk];
        [self.controlView deselectedControl:kControlTalk];
    }else {
        [self.camera startTalk:^{
            [self.controlView selectedControl:kControlTalk];
        } failure:^(NSError *error) {
            [self showAlertWithMessage:@"start talk failed" complete:nil];
        }];
    }
}

- (void)recordAction {
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            if (self.camera.isRecording) {
                [self.camera stopRecord:^{
                    [self.controlView deselectedControl:kControlRecord];
                    [self showAlertWithMessage:@"video did saved to photo library" complete:nil];
                } failure:^(NSError *error) {
                    [self showAlertWithMessage:@"video saved failed" complete:nil];
                }];
            }else {
                [self.camera startRecord:^{
                    [self.controlView selectedControl:kControlRecord];
                } failure:^(NSError *error) {
                    [self showAlertWithMessage:@"start record failed" complete:nil];
                }];
            }
        }
    }];
}

- (void)photoAction {
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            [self.camera snapShoot:^{
                [self showAlertWithMessage:@"Screenshot did saved to photo library" complete:nil];
            } failure:^(NSError *error) {
                [self showAlertWithMessage:@"Save photo failed" complete:nil];
            }];
        }
    }];
}

- (void)showAlertWithMessage:(NSString *)msg complete:(void(^)(void))complete {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        !complete?:complete();
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)checkPhotoPermision:(void(^)(BOOL result))complete {
    if ([TYPermissionUtil isPhotoLibraryNotDetermined]) {
        [TYPermissionUtil requestPhotoPermission:complete];
    }else if ([TYPermissionUtil isPhotoLibraryDenied]) {
        [self showAlertWithMessage:@"Photo permission denied" complete:nil];
        !complete?:complete(NO);
    }else {
        !complete?:complete(YES);
    }
}

#pragma mark - TuyaSmartCameraObserver
- (void)cameraDidDisconnected:(TuyaSmartCamera *)camera {
    [self.controlView disableAllControl];
    self.retryButton.hidden = NO;
}

- (void)camera:(TuyaSmartCamera *)camera didReceiveMuteState:(BOOL)isMuted {
    NSString *imageName = @"ty_camera_soundOn_icon";
    if (isMuted) {
        imageName = @"ty_camera_soundOff_icon";
    }
    [self.soundButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (void)camera:(TuyaSmartCamera *)camera didReceiveDefinitionState:(BOOL)isHd {
    NSString *imageName = @"ty_camera_control_sd_normal";
    if (isHd) {
        imageName = @"ty_camera_control_hd_normal";
    }
    [self.hdButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (void)camera:(TuyaSmartCamera *)camera didReceiveVideoFrame:(CMSampleBufferRef)sampleBuffer frameInfo:(TuyaSmartVideoFrameInfo)frameInfo {
    
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
    if ([identifier isEqualToString:kControlCloud]) {
        TYCameraCloudViewController *vc = [TYCameraCloudViewController new];
        vc.devId = self.devId;
        [self.navigationController pushViewController:vc animated:YES];
    }
    if ([identifier isEqualToString:kControlMessage]) {
        TYCameraMessageViewController *vc = [TYCameraMessageViewController new];
        vc.devId = self.devId;
        [self.navigationController pushViewController:vc animated:YES];
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
                 },
             @{
                 @"image": @"ty_camera_cloud_icon",
                 @"title": @"cloud",
                 @"identifier": kControlCloud
                 },
             @{
                 @"image": @"ty_camera_message",
                 @"title": @"message",
                 @"identifier": kControlMessage
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
