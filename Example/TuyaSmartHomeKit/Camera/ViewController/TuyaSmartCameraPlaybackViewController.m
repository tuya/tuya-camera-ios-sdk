//
//  TuyaSmartCameraPlaybackViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/14.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartCameraPlaybackViewController.h"
#import "TuyaSmartCameraControlView.h"
#import "TYPermissionUtil.h"
#import "TYCameraCalendarView.h"
#import "TYCameraRecordListView.h"
#import <TuyaSmartCameraKit/TuyaSmartCameraKit.h>
#import "TuyaSmartCamera.h"

#define TopBarHeight 88
#define VideoViewWidth [UIScreen mainScreen].bounds.size.width
#define VideoViewHeight ([UIScreen mainScreen].bounds.size.width / 16 * 9)

#define kControlRecord      @"record"
#define kControlPhoto       @"photo"

@interface TuyaSmartCameraPlaybackViewController ()<
TuyaSmartCameraObserver,
TYCameraCalendarViewDelegate,
TYCameraCalendarViewDataSource,
TYCameraRecordListViewDelegate>

@property (nonatomic, strong) UIView *videoContainer;

@property (nonatomic, strong) TYCameraCalendarView *calendarView;

@property (nonatomic, strong) UIButton *soundButton;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, strong) UIButton *retryButton;

@property (nonatomic, strong) TYNumberArray *playbackDays;

@property (nonatomic, strong) TYCameraRecordListView *recordListView;

@property (nonatomic, strong) UIButton *photoButton;

@property (nonatomic, strong) UIButton *recordButton;

@property (nonatomic, strong) UIButton *pauseButton;

@property (nonatomic, strong) UIView *controlBar;
@end

@implementation TuyaSmartCameraPlaybackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.videoContainer];
    [self.view addSubview:self.indicatorView];
    [self.view addSubview:self.stateLabel];
    [self.view addSubview:self.retryButton];
    [self.view addSubview:self.recordListView];
    [self.view addSubview:self.soundButton];
    [self.view addSubview:self.calendarView];
    [self.view addSubview:self.controlBar];
    
    [self.retryButton addTarget:self action:@selector(retryAction) forControlEvents:UIControlEventTouchUpInside];
    [self.soundButton addTarget:self action:@selector(soundAction) forControlEvents:UIControlEventTouchUpInside];
    [self.photoButton addTarget:self action:@selector(photoAction) forControlEvents:UIControlEventTouchUpInside];
    [self.recordButton addTarget:self action:@selector(recordAction) forControlEvents:UIControlEventTouchUpInside];
    [self.pauseButton addTarget:self action:@selector(pauseAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.topBarView.leftItem = self.leftBackItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (NSString *)titleForCenterItem {
    return self.camera.device.deviceModel.name;
}

- (NSString *)titleForRightItem {
    return @"date";
}

- (void)rightBtnAction {
    [self dateAction];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.camera addObserver:self];
    [self retryAction];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.camera removeObserver:self];
    [self.camera stopPlayback];
}

- (void)didEnterBackground {
    [self.camera stopPlayback];
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

- (void)stopLoadingWithText:(NSString *)text {
    [self.indicatorView stopAnimating];
    self.indicatorView.hidden = YES;
    if (text.length > 0) {
        self.stateLabel.text = text;
    }else {
        self.stateLabel.hidden = YES;
    }
}

- (void)getRecordAndPlay:(TuyaSmartPlaybackDate *)playbackDate {
    __weak typeof(self) weakSelf = self;
    self.title = [NSString stringWithFormat:@"%@-%@-%@", @(playbackDate.year), @(playbackDate.month), @(playbackDate.day)];
    [self showLoadingWithTitle:@""];
    [self.camera recordTimeSliceWithPlaybackDate:playbackDate complete:^(TYDictArray *result) {
        weakSelf.recordListView.dataSource = result;
        if (result.count > 0) {
            NSDictionary *timeslice = result.firstObject;
            [weakSelf cameraRecordListView:weakSelf.recordListView didSelectedRecord:timeslice];
        }else {
            [weakSelf stopLoadingWithText:@"No playback video"];
        }
    }];
}

- (void)enableAllControl:(BOOL)enabled {
    self.photoButton.enabled = enabled;
    self.pauseButton.enabled = enabled;
    self.recordButton.enabled = enabled;
}

#pragma mark - Action

- (void)dateAction {
    [self.view bringSubviewToFront:self.calendarView];
    [self.calendarView show:[NSDate new]];
    TuyaSmartPlaybackDate *playbackDate = [TuyaSmartPlaybackDate new];
    __weak typeof(self) weakSelf = self;
    [self.camera playbackDaysInYear:playbackDate.year month:playbackDate.month complete:^(TYNumberArray *result) {
        weakSelf.playbackDays = result;
        [weakSelf.calendarView reloadData];
    }];
}

- (void)retryAction {
    [self enableAllControl:NO];
    [self connectCamera:^(BOOL success) {
        if (success) {
            [self startPlayback];
        }else {
            [self stopLoadingWithText:@""];
            self.retryButton.hidden = NO;
        }
    }];
    [self showLoadingWithTitle:@"laoding..."];
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

- (void)startPlayback {
    [self.camera.videoView tuya_clear];
    [self.videoContainer addSubview:self.camera.videoView];
    self.camera.videoView.frame = self.videoContainer.bounds;
    [self getRecordAndPlay:[TuyaSmartPlaybackDate new]];
}

- (void)soundAction {
    [self.camera enableMute:!self.camera.isMuted success:^{
        NSLog(@"enable mute success");
    } failure:^(NSError *error) {
        [self showAlertWithMessage:@"enable mute failed" complete:nil];
    }];
}

- (void)recordAction {
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            if (self.camera.isRecording) {
                [self.camera startRecord:^{
                    self.recordButton.tintColor = [UIColor blueColor];
                } failure:^(NSError *error) {
                    [self showAlertWithMessage:@"start record failed" complete:nil];
                }];
            }else {
                [self.camera stopRecord:^{
                    self.recordButton.tintColor = [UIColor blackColor];
                    [self showAlertWithMessage:@"video did saved to photo library " complete:nil];
                } failure:^(NSError *error) {
                    [self showAlertWithMessage:@"video saved failed" complete:nil];
                }];
            }
        }
    }];
}

- (void)pauseAction {
    if (self.camera.isPlaybackPuased) {
        [self.camera resumePlayback:^{
            [self enableAllControl:YES];
            [self stopLoadingWithText:nil];
            UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_pause_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.pauseButton setImage:image forState:UIControlStateNormal];
        } failure:^(NSError *error) {
            [self showAlertWithMessage:@"resume playback failed" complete:nil];
        }];
    }else if (self.camera.isPlaybacking) {
        [self.camera pausePlayback:^{
            UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_play_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.pauseButton setImage:image forState:UIControlStateNormal];
            self.recordButton.enabled = NO;
        } failure:^(NSError *error) {
            [self showAlertWithMessage:@"pause playback failed" complete:nil];
        }];
    }
}

- (void)photoAction {
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            [self.camera snapShoot:^{
                [self showAlertWithMessage:@"picture did saved to photo library" complete:nil];
            } failure:^(NSError *error) {
                [self showAlertWithMessage:@"pciture saved failed" complete:nil];
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

#pragma mark - TYCameraRecordListViewDelegate

- (void)cameraRecordListView:(TYCameraRecordListView *)listView didSelectedRecord:(NSDictionary *)timeslice {
    [self showLoadingWithTitle:@""];
    NSInteger startTime = [[timeslice objectForKey:kTuyaSmartTimeSliceStartTime] integerValue];
    [self.camera startPlaybackWithPlayTime:startTime playbackSlice:timeslice success:^{
        [self stopLoadingWithText:@""];
    } failure:^(NSError *error) {
        [self showAlertWithMessage:@"playback failed" complete:nil];
    }];
}

#pragma mark - TYCameraCalendarViewDataSource

- (BOOL)calendarView:(TYCameraCalendarView *)calendarView hasVideoOnYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    if (!self.playbackDays) {
        return NO;
    }
    return [self.playbackDays containsObject:@(day)];
}

#pragma mark - TYCameraCalendarViewDelegate

- (void)calendarView:(TYCameraCalendarView *)calendarView didSelectYear:(NSInteger)year month:(NSInteger)month {
    self.playbackDays = nil;
    [self showLoadingWithTitle:@""];
    [self.camera playbackDaysInYear:year month:month complete:^(TYNumberArray *result) {
        [self stopLoadingWithText:@""];
        self.playbackDays = result;
        [calendarView reloadData];
    }];
}

- (void)calendarView:(TYCameraCalendarView *)calendarView didSelectYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day date:(NSDate *)date {
    [calendarView hide];
    [self getRecordAndPlay:[TuyaSmartPlaybackDate playbackDateWithDate:date]];
}

#pragma mark - TuyaSmartCameraObserver

- (void)cameraPlaybackDidFinished:(TuyaSmartCamera *)camera {
    [self enableAllControl:NO];
    [self stopLoadingWithText:@"video finished"];
}

- (void)camera:(TuyaSmartCamera *)camera didReceiveMuteState:(BOOL)isMuted {
    NSString *imageName = @"ty_camera_soundOn_icon";
    if (isMuted) {
        imageName = @"ty_camera_soundOff_icon";
    }
    [self.soundButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
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
    return @[
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
             ];
}

- (UIButton *)soundButton {
    if (!_soundButton) {
        _soundButton = [[UIButton alloc] initWithFrame:CGRectMake(8, TopBarHeight + VideoViewHeight - 50, 44, 44)];
        [_soundButton setImage:[UIImage imageNamed:@"ty_camera_soundOff_icon"] forState:UIControlStateNormal];
    }
    return _soundButton;
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

- (TYCameraCalendarView *)calendarView {
    if (!_calendarView) {
        _calendarView = [[TYCameraCalendarView alloc] initWithFrame:CGRectZero];
        _calendarView.dataSource = self;
        _calendarView.delegate = self;
    }
    return _calendarView;
}

- (TYCameraRecordListView *)recordListView {
    if (!_recordListView) {
        CGFloat top = VideoViewHeight + TopBarHeight + 50;
        CGFloat width = self.view.frame.size.width;
        CGFloat height = self.view.frame.size.height - top;
        _recordListView = [[TYCameraRecordListView alloc] initWithFrame:CGRectMake(0, top, width, height)];
        _recordListView.delegate = self;
    }
    return _recordListView;
}

- (UIButton *)photoButton {
    if (!_photoButton) {
        _photoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        UIImage *image = [[UIImage imageNamed:@"ty_camera_photo_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_photoButton setImage:image forState:UIControlStateNormal];
        [_photoButton setTintColor:[UIColor blackColor]];
    }
    return _photoButton;
}

- (UIButton *)recordButton {
    if (!_recordButton) {
        _recordButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        UIImage *image = [[UIImage imageNamed:@"ty_camera_rec_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_recordButton setImage:image forState:UIControlStateNormal];
        [_recordButton setTintColor:[UIColor blackColor]];
    }
    return _recordButton;
}

- (UIButton *)pauseButton {
    if (!_pauseButton) {
        _pauseButton = [[UIButton alloc] init];
        UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_pause_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_pauseButton setImage:image forState:UIControlStateNormal];
        [_pauseButton setTintColor:[UIColor blackColor]];
    }
    return _pauseButton;
}

- (UIView *)controlBar {
    if (!_controlBar) {
        CGFloat top = VideoViewHeight + TopBarHeight;
        _controlBar = [[UIView alloc] initWithFrame:CGRectMake(0, top, VideoViewWidth, 50)];
        [_controlBar addSubview:self.photoButton];
        [_controlBar addSubview:self.pauseButton];
        [_controlBar addSubview:self.recordButton];
        CGFloat width = VideoViewWidth / 3;
        [_controlBar.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
            obj.frame = CGRectMake(width * idx, 0, width, 50);
        }];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 49.5, VideoViewWidth, 0.5)];
        line.backgroundColor = [UIColor lightGrayColor];
        [_controlBar addSubview:line];
    }
    return _controlBar;
}

@end
