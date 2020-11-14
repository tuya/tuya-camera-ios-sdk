//
//  TYDemoCameraPlaybackViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/14.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TYDemoCameraPlaybackViewController.h"
#import "TuyaSmartCameraControlView.h"
#import "TYPermissionUtil.h"
#import "TYCameraCalendarView.h"
#import "TuyaSmartCamera.h"
#import "TPDemoViewConstants.h"
#import "TPDemoProgressUtils.h"
#import "TYCameraTimeLineModel.h"
#import <YYModel/YYModel.h>

#define VideoViewWidth [UIScreen mainScreen].bounds.size.width
#define VideoViewHeight ([UIScreen mainScreen].bounds.size.width / 16 * 9)

#define kControlRecord      @"record"
#define kControlPhoto       @"photo"

@interface TYDemoCameraPlaybackViewController ()<
TuyaSmartCameraObserver,
TYCameraCalendarViewDelegate,
TYCameraCalendarViewDataSource,
TuyaTimelineViewDelegate>

@property (nonatomic, strong) UIView *videoContainer;

@property (nonatomic, strong) TYCameraCalendarView *calendarView;

@property (nonatomic, strong) UIButton *soundButton;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, strong) UIButton *retryButton;

@property (nonatomic, strong) NSMutableArray<NSNumber *> *playbackDays;

@property (nonatomic, strong) UIButton *photoButton;

@property (nonatomic, strong) UIButton *recordButton;

@property (nonatomic, strong) UIButton *pauseButton;

@property (nonatomic, strong) UIView *controlBar;

@property (nonatomic, strong) TuyaSmartPlaybackDate *currentDate;

@property (nonatomic, strong) TuyaTimelineView *timeLineView;

@property (nonatomic, strong) NSArray *timeLineModels;

@property (nonatomic, assign) NSInteger playTime;

@property (nonatomic, strong) TYCameraTimeLabel *timeLineLabel;

@end

@implementation TYDemoCameraPlaybackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = HEXCOLOR(0xd8d8d8);
    [self.view addSubview:self.videoContainer];
    [self.view addSubview:self.indicatorView];
    [self.view addSubview:self.stateLabel];
    [self.view addSubview:self.retryButton];
    [self.view addSubview:self.timeLineView];
    [self.view addSubview:self.soundButton];
    [self.view addSubview:self.calendarView];
    [self.view addSubview:self.controlBar];
    [self.view addSubview:self.timeLineLabel];
    
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
    return NSLocalizedString(@"ipc_panel_button_calendar", @"");
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
    self.title = [NSString stringWithFormat:@"%@-%@-%@", @(playbackDate.year), @(playbackDate.month), @(playbackDate.day)];
    self.currentDate = playbackDate;
    __weak typeof(self) weakSelf = self;
    [self showLoadingWithTitle:@""];
    [self.camera requestTimeSliceWithPlaybackDate:playbackDate complete:^(TYDictArray *result) {
        if (result.count > 0) {
            weakSelf.timeLineModels = [NSArray yy_modelArrayWithClass:[TYCameraTimeLineModel class] json:result];
            weakSelf.timeLineView.sourceModels = weakSelf.timeLineModels;
            [weakSelf.timeLineView setCurrentTime:0 animated:YES];
        }else {
            [weakSelf stopLoadingWithText:NSLocalizedString(@"ipc_playback_no_records_today", @"")];
        }
    }];
}

- (void)enableAllControl:(BOOL)enabled {
    self.photoButton.enabled = enabled;
    self.pauseButton.enabled = enabled;
    self.recordButton.enabled = enabled;
}

- (NSString *)timeStringWithTimestamp:(NSInteger)timestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm:ss";
    return [dateFormatter stringFromDate:date];
}

#pragma mark - Action

- (void)dateAction {
    [self.view bringSubviewToFront:self.calendarView];
    [self.calendarView show:[NSDate new]];
    TuyaSmartPlaybackDate *playbackDate = [TuyaSmartPlaybackDate new];
    __weak typeof(self) weakSelf = self;
    [self.camera playbackDaysInYear:playbackDate.year month:playbackDate.month complete:^(TYNumberArray *result) {
        weakSelf.playbackDays = result.mutableCopy;
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
    [self showLoadingWithTitle:NSLocalizedString(@"loading", @"")];
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

- (void)playbackWithTime:(NSInteger)playTime timeLineModel:(TYCameraTimeLineModel *)model {
    playTime = [model containsPlayTime:playTime] ? playTime : model.startTime;
    [self showLoadingWithTitle:@""];
    [self.camera startPlaybackWithPlayTime:playTime timelineModel:model success:^{
        [self enableAllControl:YES];
        [self stopLoadingWithText:@""];
    } failure:^(NSError *error) {
        [TPDemoProgressUtils showError:NSLocalizedString(@"ipc_errmsg_record_play_failed", @"")];
    }];
}

- (void)soundAction {
    [self.camera enableMute:!self.camera.isMuted success:^{
        NSLog(@"enable mute success");
    } failure:^(NSError *error) {
        [self showAlertWithMessage:NSLocalizedString(@"fail", @"") complete:nil];
    }];
}

- (void)recordAction {
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            if (self.camera.isRecording) {
                [self.camera stopRecord:^{
                    self.recordButton.tintColor = [UIColor blackColor];
                    [self showAlertWithMessage:NSLocalizedString(@"ipc_multi_view_video_saved", @"") complete:nil];
                } failure:^(NSError *error) {
                    [TPDemoProgressUtils showError:NSLocalizedString(@"record failed", @"")];
                }];
            }else {
                [self.camera startRecord:^{
                    self.recordButton.tintColor = [UIColor blueColor];
                } failure:^(NSError *error) {
                    [TPDemoProgressUtils showError:NSLocalizedString(@"record failed", @"")];
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
            [self showAlertWithMessage:NSLocalizedString(@"fail", @"") complete:nil];
        }];
    }else if (self.camera.isPlaybacking) {
        [self.camera pausePlayback:^{
            UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_play_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.pauseButton setImage:image forState:UIControlStateNormal];
            self.recordButton.enabled = NO;
        } failure:^(NSError *error) {
            [self showAlertWithMessage:NSLocalizedString(@"fail", @"") complete:nil];
        }];
    }
}

- (void)photoAction {
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            [self.camera snapShoot:^{
                [self showAlertWithMessage:NSLocalizedString(@"ipc_multi_view_photo_saved", @"") complete:nil];
            } failure:^(NSError *error) {
                [self showAlertWithMessage:NSLocalizedString(@"fail", @"") complete:nil];
            }];
        }
    }];
}

- (void)showAlertWithMessage:(NSString *)msg complete:(void(^)(void))complete {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"ipc_settings_ok", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        !complete?:complete();
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)checkPhotoPermision:(void(^)(BOOL result))complete {
    if ([TYPermissionUtil isPhotoLibraryNotDetermined]) {
        [TYPermissionUtil requestPhotoPermission:complete];
    }else if ([TYPermissionUtil isPhotoLibraryDenied]) {
        [self showAlertWithMessage:NSLocalizedString(@"Photo library permission denied", @"") complete:nil];
        !complete?:complete(NO);
    }else {
        !complete?:complete(YES);
    }
}

#pragma mark - TuyaTimelineViewDelegate

- (void)timelineViewWillBeginDragging:(TuyaTimelineView *)timeLineView {
    
}

- (void)timelineViewDidEndDragging:(TuyaTimelineView *)timeLineView willDecelerate:(BOOL)decelerate {
    
}

- (void)timelineViewDidScroll:(TuyaTimelineView *)timeLineView time:(NSTimeInterval)timeInterval isDragging:(BOOL)isDragging {
    self.timeLineLabel.hidden = NO;
    self.timeLineLabel.timeStr = [NSDate tysdk_timeStringWithTimeInterval:timeInterval timeZone:[NSTimeZone localTimeZone]];
}

- (void)timelineView:(TuyaTimelineView *)timeLineView didEndScrollingAtTime:(NSTimeInterval)timeInterval inSource:(id<TuyaTimelineViewSource>)source {
    self.timeLineLabel.hidden = YES;
    if (source) {
        [self playbackWithTime:timeInterval timeLineModel:source];
    }
}

- (NSString *)_durationTimeStampWithStart:(NSDate *)start end:(NSDate *)end {
    NSInteger duration = [end timeIntervalSinceDate:start];
    int h =(int)(duration / 60 / 60);
    int m = (duration / 60) % 60;
    int s = duration % 60;
    return [NSString stringWithFormat:@"%@：%02d:%02d:%02d", NSLocalizedString(@"Duration", @""), h, m, s];
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
        self.playbackDays = [result mutableCopy];
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
    [self stopLoadingWithText:NSLocalizedString(@"ipc_video_end", @"")];
}

- (void)camera:(TuyaSmartCamera *)camera didReceiveMuteState:(BOOL)isMuted {
    NSString *imageName = @"ty_camera_soundOn_icon";
    if (isMuted) {
        imageName = @"ty_camera_soundOff_icon";
    }
    [self.soundButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (void)camera:(TuyaSmartCamera *)camera didReceiveVideoFrame:(CMSampleBufferRef)sampleBuffer frameInfo:(TuyaSmartVideoFrameInfo)frameInfo {
    if (self.playTime != frameInfo.nTimeStamp) {
        self.playTime = frameInfo.nTimeStamp;
        if (!self.timeLineView.isDecelerating && !self.timeLineView.isDragging) {
            [self.timeLineView setCurrentTime:self.playTime];
        }
    }
}


#pragma mark - Accessor

- (UIView *)videoContainer {
    if (!_videoContainer) {
        _videoContainer = [[UIView alloc] initWithFrame:CGRectMake(0, APP_TOP_BAR_HEIGHT, VideoViewWidth, VideoViewHeight)];
        _videoContainer.backgroundColor = [UIColor blackColor];
    }
    return _videoContainer;
}

- (UIButton *)soundButton {
    if (!_soundButton) {
        _soundButton = [[UIButton alloc] initWithFrame:CGRectMake(8, APP_TOP_BAR_HEIGHT + VideoViewHeight - 50, 44, 44)];
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
        [_retryButton setTitle:NSLocalizedString(@"connect failed, click retry", @"") forState:UIControlStateNormal];
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
        CGFloat top = APP_SCREEN_HEIGHT - 50;
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
        _controlBar.backgroundColor = [UIColor whiteColor];
    }
    return _controlBar;
}

- (TuyaTimelineView *)timeLineView {
    if (!_timeLineView) {
        _timeLineView = [[TuyaTimelineView alloc] initWithFrame:CGRectMake(0, self.videoContainer.bottom, [UIScreen mainScreen].bounds.size.width, 150)];
        _timeLineView.timeHeaderHeight = 24;
        _timeLineView.showShortMark = YES;
        _timeLineView.spacePerUnit = 90;
        _timeLineView.timeTextTop = 6;
        _timeLineView.delegate = self;
        _timeLineView.backgroundColor = HEXCOLOR(0xf5f5f5);
        _timeLineView.backgroundGradientColors = @[];
        _timeLineView.contentGradientColors = @[(__bridge id)HEXCOLORA(0x4f67ee, 0.62).CGColor, (__bridge id)HEXCOLORA(0x4d67ff, 0.09).CGColor];
        _timeLineView.contentGradientLocations = @[@(0.0), @(1.0)];
        _timeLineView.timeStringAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:9], NSForegroundColorAttributeName : HEXCOLOR(0x999999)};
        _timeLineView.tickMarkColor = HEXCOLORA(0x000000, 0.1);
        _timeLineView.timeZone = [NSTimeZone localTimeZone];
    }
    return _timeLineView;
}


- (TYCameraTimeLabel *)timeLineLabel {
    if (!_timeLineLabel) {
        _timeLineLabel = [[TYCameraTimeLabel alloc] initWithFrame:CGRectMake((self.timeLineView.width - 74) / 2, self.timeLineView.top, 74, 22)];
        _timeLineLabel.position = 2;
        _timeLineLabel.hidden = YES;
        _timeLineLabel.ty_backgroundColor = [UIColor blackColor];
        _timeLineLabel.textColor = [UIColor whiteColor];
    }
    return _timeLineLabel;
}

@end
