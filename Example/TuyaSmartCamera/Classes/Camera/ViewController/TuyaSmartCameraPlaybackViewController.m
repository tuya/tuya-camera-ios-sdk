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
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"date" style:UIBarButtonItemStylePlain target:self action:@selector(dateAction)];
    self.navigationItem.rightBarButtonItem = item;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.camera addObserVer:self];
    [self retryAction];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
    WEAKSELF_AT
    self.title = [NSString stringWithFormat:@"%@-%@-%@", @(playbackDate.year), @(playbackDate.month), @(playbackDate.day)];
    [self.camera recordTimeSliceWithPlaybackDate:playbackDate complete:^(TYDictArray *result) {
        weakSelf_AT.recordListView.dataSource = result;
        if (result.count > 0) {
            NSDictionary *timeslice = result.firstObject;
            [weakSelf_AT cameraRecordListView:weakSelf_AT.recordListView didSelectedRecord:timeslice];
        }else {
            [weakSelf_AT stopLoadingWithText:@"No playback video"];
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
    WEAKSELF_AT
    [self.camera playbackDaysInYear:playbackDate.year month:playbackDate.month complete:^(TYNumberArray *result) {
        weakSelf_AT.playbackDays = result;
        [weakSelf_AT.calendarView reloadData];
    }];
}

- (void)retryAction {
    [self enableAllControl:NO];
    if ([self.camera isConnected]) {
        [self.camera.videoView tuya_clear];
        [self.videoContainer addSubview:self.camera.videoView];
        self.camera.videoView.frame = self.videoContainer.bounds;
        [self getRecordAndPlay:[TuyaSmartPlaybackDate new]];
    }else {
        [self.camera connect];
    }
    [self showLoadingWithTitle:@"laoding..."];
    self.retryButton.hidden = YES;
}

- (void)soundAction {
    self.camera.muted = !self.camera.isMuted;
}

- (void)recordAction {
    WEAKSELF_AT
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            if (weakSelf_AT.camera.isRecording) {
                [weakSelf_AT.camera stopRecord];
            }else {
                [weakSelf_AT.camera startRecord];
            }
        }
    }];
}

- (void)pauseAction {
    if (self.camera.isPlaybackPuased) {
        [self.camera resumePlayback];
    }else if (self.camera.isPlaybacking) {
        [self.camera pausePlayback];
    }
}

- (void)photoAction {
    WEAKSELF_AT
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            if ([weakSelf_AT.camera snapShoot]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Screenshot did saved to photo library" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:action];
                [weakSelf_AT presentViewController:alert animated:YES completion:nil];
            }
        }
    }];
}

- (void)checkPhotoPermision:(void(^)(BOOL result))complete {
    if ([TYPermissionUtil isPhotoLibraryNotDetermined]) {
        [TYPermissionUtil requestPhotoPermission:complete];
    }else if ([TYPermissionUtil isPhotoLibraryDenied]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Photo permission denied" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
        !complete?:complete(NO);
    }else {
        !complete?:complete(YES);
    }
}

#pragma mark - TYCameraRecordListViewDelegate

- (void)cameraRecordListView:(TYCameraRecordListView *)listView didSelectedRecord:(NSDictionary *)timeslice {
    NSInteger startTime = [[timeslice objectForKey:kTuyaSmartTimeSliceStartTime] integerValue];
    [self.camera startPlaybackWithPlayTime:startTime playbackSlice:timeslice];
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
    WEAKSELF_AT
    self.playbackDays = nil;
    [self.camera playbackDaysInYear:year month:month complete:^(TYNumberArray *result) {
        weakSelf_AT.playbackDays = result;
        [calendarView reloadData];
    }];
}

- (void)calendarView:(TYCameraCalendarView *)calendarView didSelectYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day date:(NSDate *)date {
    [calendarView hide];
    
    [self getRecordAndPlay:[TuyaSmartPlaybackDate playbackDateWithDate:date]];
}

#pragma mark - TuyaSmartCameraObserver

- (void)cameraDidConnected:(TuyaSmartCameraDefault *)camera {
    [self.camera.videoView tuya_clear];
    [self.videoContainer addSubview:self.camera.videoView];
    self.camera.videoView.frame = self.videoContainer.bounds;
    [self getRecordAndPlay:[TuyaSmartPlaybackDate new]];
}

- (void)camera:(TuyaSmartCameraDefault *)camera playbackStateDidChagned:(TuyaSmartCameraPlaybackState)playbackState {
    switch (playbackState) {
        case TuyaSmartCameraPlaybackStatePlaying: {
            [self enableAllControl:YES];
            [self stopLoadingWithText:nil];
            UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_pause_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.pauseButton setImage:image forState:UIControlStateNormal];
        }
            break;
        case TuyaSmartCameraPlaybackStateLoading:
            [self enableAllControl:NO];
            [self showLoadingWithTitle:@"loading..."];
            break;
        case TuyaSmartCameraPlaybackStatePaused: {
            UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_play_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.pauseButton setImage:image forState:UIControlStateNormal];
            self.recordButton.enabled = NO;
        }
            break;
        case TuyaSmartCameraPlaybackStateFinished:
            [self enableAllControl:NO];
            break;
        default:
            break;
    }
}

- (void)camera:(TuyaSmartCameraDefault *)camera muteStateDidChanged:(BOOL)isMuted {
    NSString *imageName = @"ty_camera_soundOn_icon";
    if (isMuted) {
        imageName = @"ty_camera_soundOff_icon";
    }
    [self.soundButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (void)cameraDidStartRecording:(TuyaSmartCameraDefault *)camera {
    self.recordButton.tintColor = [UIColor blueColor];
}

- (void)cameraDidStopRecording:(TuyaSmartCameraDefault *)camera {
    self.recordButton.tintColor = [UIColor blackColor];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"video did saved to photo library" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)camera:(TuyaSmartCameraDefault *)camera didOccurredError:(TYCameraErrorCode)errCode {
    NSString *errString = nil;
    switch (errCode) {
        case TY_ERROR_CONNECT_FAILED:
        case TY_ERROR_QUERY_TIMESLICE_FAILED:
        case TY_ERROR_START_PLAYBACK_FAILED:
            [self stopLoadingWithText:nil];
            self.retryButton.hidden = NO;
            break;
        case TY_ERROR_QUERY_RECORD_DAY_FAILED:
            errString = @"network error";
            break;
        case TY_ERROR_RECORD_FAILED:
            errString = @"recording falied";
            break;
        case TY_ERROR_ENABLE_MUTE_FAILED:
            errString = @"enable mute failed";
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
