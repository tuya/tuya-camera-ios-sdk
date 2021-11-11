//
//  TYDemoCameraPlaybackViewController.m
//  TuyaSmartCamera_Example
//
//  Copyright (c) 2014-2021 Tuya Inc. (https://developer.tuya.com/)

#import "TYDemoCameraPlaybackViewController.h"
#import "TuyaSmartCameraControlView.h"
#import "TYPermissionUtil.h"
#import "TYCameraCalendarView.h"
#import "TYCameraRecordListView.h"
#import "TuyaSmartCamera.h"
#import "TPDemoViewConstants.h"
#import "TPDemoProgressUtils.h"
#import "TYDownloadingProgressView.h"

#define VideoViewWidth [UIScreen mainScreen].bounds.size.width
#define VideoViewHeight ([UIScreen mainScreen].bounds.size.width / 16 * 9)

#define kControlRecord      @"record"
#define kControlPhoto       @"photo"

@interface TYDemoCameraPlaybackViewController ()<
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

@property (nonatomic, strong) NSMutableArray<NSNumber *> *playbackDays;

@property (nonatomic, strong) TYCameraRecordListView *recordListView;

@property (nonatomic, strong) UIButton *photoButton;

@property (nonatomic, strong) UIButton *recordButton;

@property (nonatomic, strong) UIButton *pauseButton;

@property (nonatomic, strong) UIButton *downloadButton;

@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) UIView *controlBar;

@property (nonatomic, strong) UIButton *speedButton;


@property (nonatomic, strong) UILabel *startTimeLabel;
@property (nonatomic, strong) UISlider *startTimeSlider;
@property (nonatomic, strong) UILabel *endTimeLabel;
@property (nonatomic, strong) UISlider *endTimeSlider;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIView *downloadView;

@property (nonatomic, assign) NSInteger downloadStartTime;
@property (nonatomic, assign) NSInteger downloadEndTime;

@property (nonatomic, strong) TYDownloadingProgressView *progressView;

@property (nonatomic, strong) TuyaSmartPlaybackDate *currentDate;

@end

@implementation TYDemoCameraPlaybackViewController

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
    [self.view addSubview:self.speedButton];
    
    [self.retryButton addTarget:self action:@selector(retryAction) forControlEvents:UIControlEventTouchUpInside];
    [self.soundButton addTarget:self action:@selector(soundAction) forControlEvents:UIControlEventTouchUpInside];
    [self.speedButton addTarget:self action:@selector(speedButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.photoButton addTarget:self action:@selector(photoAction) forControlEvents:UIControlEventTouchUpInside];
    [self.recordButton addTarget:self action:@selector(recordAction) forControlEvents:UIControlEventTouchUpInside];
    [self.pauseButton addTarget:self action:@selector(pauseAction) forControlEvents:UIControlEventTouchUpInside];
    [self.downloadButton addTarget:self action:@selector(downloadAction) forControlEvents:UIControlEventTouchUpInside];
    [self.deleteButton addTarget:self action:@selector(deleteButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
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
        weakSelf.recordListView.dataSource = result;
        if (result.count > 0) {
            NSDictionary *timeslice = result.firstObject;
            [weakSelf cameraRecordListView:weakSelf.recordListView didSelectedRecord:timeslice];
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

- (void)setupDownloadView {
    if (!_downloadView) {
        _downloadView = [[UIView alloc] initWithFrame:self.recordListView.frame];
        _downloadView.backgroundColor = [UIColor whiteColor];
        [_downloadView addSubview:self.startTimeLabel];
        [_downloadView addSubview:self.endTimeLabel];
        [_downloadView addSubview:self.startTimeSlider];
        [_downloadView addSubview:self.endTimeSlider];
        [_downloadView addSubview:self.confirmButton];
        self.startTimeLabel.frame = CGRectMake(8, 8, CGRectGetWidth(_downloadView.frame) - 16, 20);
        self.startTimeSlider.frame = CGRectMake(8, 28, CGRectGetWidth(_downloadView.frame) - 16, 56);
        self.endTimeLabel.frame = CGRectMake(8, 108, CGRectGetWidth(_downloadView.frame)-16, 20);
        self.endTimeSlider.frame = CGRectMake(8, 128, CGRectGetWidth(_downloadView.frame) - 16, 56);
        self.confirmButton.frame = CGRectMake(0, 0, 200, 40);
        self.confirmButton.center = CGPointMake(CGRectGetMidX(_downloadView.bounds), CGRectGetHeight(_downloadView.bounds)-35);
        [self.confirmButton addTarget:self action:@selector(downloadConfirmAction) forControlEvents:UIControlEventTouchUpInside];
        [self.startTimeSlider addTarget:self action:@selector(startTimeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.endTimeSlider addTarget:self action:@selector(endTimeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    NSInteger startTime = [self startTimestamp];
    NSInteger endTime = [self endTimestamp];
    self.startTimeLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Start", @""), [self timeStringWithTimestamp:startTime]];
    self.endTimeLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"End", @""), [self timeStringWithTimestamp:endTime]];
    self.startTimeSlider.value = 0.0;
    self.endTimeSlider.value = 1.0;
    self.downloadStartTime = startTime;
    self.downloadEndTime = endTime;
}

- (NSInteger)startTimestamp {
    if (self.recordListView.dataSource.count == 0) {
        return 0;
    }
    return [[self.recordListView.dataSource.firstObject objectForKey:kTuyaSmartTimeSliceStartTime] integerValue];
}

- (NSInteger)endTimestamp {
    if (self.recordListView.dataSource.count == 0) {
        return 0;
    }
    return [[self.recordListView.dataSource.lastObject objectForKey:kTuyaSmartTimeSliceStopTime] integerValue];
}

- (NSString *)timeStringWithTimestamp:(NSInteger)timestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm:ss";
    return [dateFormatter stringFromDate:date];
}

#pragma mark - Action
- (void)speedButtonAction {
    __weak typeof(self) weakSelf = self;
    UIAlertController *speedSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *speed_20x = [UIAlertAction actionWithTitle:@"2.0x" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.camera setPlaybackSpeed:TuyaSmartCameraPlaybackSpeed2_0x callback:^(int errCode) {
            if (errCode != 0) {
                [TPDemoProgressUtils showError:NSLocalizedString(@"Change Speed Failed", @"")];
            }else {
                [weakSelf.speedButton setTitle:@"2.0x" forState:UIControlStateNormal];
            }
        }];
    }];
    
    UIAlertAction *speed_10x = [UIAlertAction actionWithTitle:@"1.0x" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.camera setPlaybackSpeed:TuyaSmartCameraPlaybackSpeed1_0x callback:^(int errCode) {
            if (errCode != 0) {
                [TPDemoProgressUtils showError:NSLocalizedString(@"Change Speed Failed", @"")];
            }else {
                [weakSelf.speedButton setTitle:@"1.0x" forState:UIControlStateNormal];
            }
        }];
    }];
    
    [speedSheet addAction:speed_10x];
    [speedSheet addAction:speed_20x];
    [self presentViewController:speedSheet animated:YES completion:nil];
}
- (void)deleteButtonAction {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"ipc_cloud_delete_comfirm_today", @"") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:NSLocalizedString(@"ipc_confirm_sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self deleteVideos];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"ipc_confirm_cancel", @"") style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancel];
    [alert addAction:confirm];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteVideos {
    if (!self.currentDate) {
        return;
    }
    [self.camera stopPlayback];
    
    __weak typeof(self) weakSelf = self;
    [TPDemoProgressUtils showMessag:@"" toView:self.view];
    [self.camera deletePlaybackVideoWithDate:self.currentDate callback:^(int errCode) {
        [TPDemoProgressUtils hideHUDForView:weakSelf.view animated:YES];
        if (errCode == 0) {
            [weakSelf.playbackDays removeObject:@(weakSelf.currentDate.day)];
            [TPDemoProgressUtils showSuccess:NSLocalizedString(@"ipc_cloud_delete_success", @"") toView:weakSelf.view];
        }else {
            [TPDemoProgressUtils showError:NSLocalizedString(@"ipc_cloud_delete_failure", @"")];
        }
    }];
}

- (void)downloadAction {
    if (self.downloadView.superview) {
        [self.downloadView removeFromSuperview];
    }else {
        [self setupDownloadView];
        [self.view addSubview:self.downloadView];
    }
}

- (void)downloadConfirmAction {
    if (self.downloadEndTime <= self.downloadStartTime) {
        return;
    }
    [self checkPhotoPermision:^(BOOL result) {
        [self doPlaybackDownload];
    }];
}

- (void)doPlaybackDownload {
    [self.progressView show];
    self.progressView.progress = 0;
    __weak typeof(self) weakSelf = self;
    [self.camera downloadPlaybackVideoWithStartTime:self.downloadStartTime endTime:self.downloadEndTime success:^(NSString *filePath) {
        [weakSelf.progressView hide];
        if ([TYCameraUtil saveVideoToPhotoLibrary:filePath]) {
            [TPDemoProgressUtils showSuccess:NSLocalizedString(@"ipc_cloud_download_complete", @"") toView:weakSelf.view];
        }else {
            [TPDemoProgressUtils showError:NSLocalizedString(@"Video failed save to photo library", @"")];
        }
    } progress:^(int progress) {
        [weakSelf.progressView setProgress:progress];
    } failure:^(int errCode) {
        [weakSelf.progressView hide];
        [TPDemoProgressUtils showError:NSLocalizedString(@"ipc_cloud_download_failed", @"")];
    }];
    
    self.progressView.cancelAction = ^{
        [weakSelf.camera cancelDownloadPlayback];
        [weakSelf.progressView hide];
    };
}

- (void)startTimeSliderValueChanged:(UISlider *)slider {
    NSInteger startTimestamp = [self startTimestamp];
    NSInteger endTimestamp = [self endTimestamp];
    self.downloadStartTime = (endTimestamp - startTimestamp) * slider.value + startTimestamp;
    self.startTimeLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Start", @""), [self timeStringWithTimestamp:self.downloadStartTime]];
}

- (void)endTimeSliderValueChanged:(UISlider *)slider {
    NSInteger startTimestamp = [self startTimestamp];
    NSInteger endTimestamp = [self endTimestamp];
    self.downloadEndTime = (endTimestamp - startTimestamp) * slider.value + startTimestamp;
    self.endTimeLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"End", @""), [self timeStringWithTimestamp:self.downloadEndTime]];
}

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
                [self.camera startRecord:^{
                    self.recordButton.tintColor = [UIColor blueColor];
                } failure:^(NSError *error) {
                    [TPDemoProgressUtils showError:NSLocalizedString(@"record failed", @"")];
                }];
            }else {
                [self.camera stopRecord:^{
                    self.recordButton.tintColor = [UIColor blackColor];
                    [self showAlertWithMessage:NSLocalizedString(@"ipc_multi_view_video_saved", @"") complete:nil];
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

#pragma mark - TYCameraRecordListViewDelegate

- (void)cameraRecordListView:(TYCameraRecordListView *)listView didSelectedRecord:(NSDictionary *)timeslice {
    [self showLoadingWithTitle:@""];
    NSInteger startTime = [[timeslice objectForKey:kTuyaSmartTimeSliceStartTime] integerValue];
    [self.camera startPlaybackWithPlayTime:startTime playbackSlice:timeslice success:^{
        [self enableAllControl:YES];
        [self stopLoadingWithText:@""];
    } failure:^(NSError *error) {
        [TPDemoProgressUtils showError:NSLocalizedString(@"ipc_errmsg_record_play_failed", @"")];
    }];
}

- (void)cameraRecordListView:(TYCameraRecordListView *)listView presentCell:(TYCameraRecordCell *)cell source:(id)source {
    NSDate *startDate = source[kTuyaSmartTimeSliceStartDate];
    NSDate *stopDate = source[kTuyaSmartTimeSliceStopDate];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    formatter.dateFormat = @"HH:mm:ss";
    cell.startTimeLabel.text = [formatter stringFromDate:startDate];
    cell.durationLabel.text  = [self _durationTimeStampWithStart:startDate end:stopDate];
    [cell.durationLabel sizeToFit];

    [self.camera downloadThumbnailsWithTimeSlice:source complete:^(UIImage *image, int errCode) {
        cell.iconImageView.image = image;
    }];
    
    TuyaSmartCameraPlaybackType type = [source[kTuyaSmartTimeSliceType] intValue];
    switch (type) {
        case TuyaSmartCameraPlaybackNormal:
            cell.typeLabel.text = @"Normal";
            break;
        case TuyaSmartCameraPlaybackMotionDetection:
            cell.typeLabel.text = @"Motion";
            break;
        case TuyaSmartCameraPlaybackFaceDetection:
            cell.typeLabel.text = @"Face";
            break;
        case TuyaSmartCameraPlaybackBodyDetection:
            cell.typeLabel.text = @"Body";
            break;
        default:
            cell.typeLabel.text = @"Other";
            break;
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

- (TYCameraRecordListView *)recordListView {
    if (!_recordListView) {
        CGFloat top = VideoViewHeight + APP_TOP_BAR_HEIGHT + 50;
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

- (UIButton *)downloadButton {
    if (!_downloadButton) {
        _downloadButton = [[UIButton alloc] init];
        UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_download_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_downloadButton setImage:image forState:UIControlStateNormal];
        [_downloadButton setTintColor:[UIColor blackColor]];
    }
    return _downloadButton;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [[UIButton alloc] init];
        UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_delete_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_deleteButton setImage:image forState:UIControlStateNormal];
        [_deleteButton setTintColor:[UIColor blackColor]];
    }
    return _deleteButton;
}

- (UIView *)controlBar {
    if (!_controlBar) {
        CGFloat top = VideoViewHeight + APP_TOP_BAR_HEIGHT;
        _controlBar = [[UIView alloc] initWithFrame:CGRectMake(0, top, VideoViewWidth, 50)];
        [_controlBar addSubview:self.photoButton];
        [_controlBar addSubview:self.pauseButton];
        [_controlBar addSubview:self.recordButton];
        [_controlBar addSubview:self.downloadButton];
        [_controlBar addSubview:self.deleteButton];
        CGFloat width = VideoViewWidth / 5;
        [_controlBar.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
            obj.frame = CGRectMake(width * idx, 0, width, 50);
        }];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 49.5, VideoViewWidth, 0.5)];
        line.backgroundColor = [UIColor lightGrayColor];
        [_controlBar addSubview:line];
    }
    return _controlBar;
}

- (UILabel *)startTimeLabel {
    if (!_startTimeLabel) {
        _startTimeLabel = [[UILabel alloc] init];
        _startTimeLabel.textColor = [UIColor blackColor];
    }
    return _startTimeLabel;
}

- (UISlider *)startTimeSlider {
    if (!_startTimeSlider) {
        _startTimeSlider = [[UISlider alloc] init];
    }
    return _startTimeSlider;
}

- (UILabel *)endTimeLabel {
    if (!_endTimeLabel) {
        _endTimeLabel = [[UILabel alloc] init];
        _endTimeLabel.textColor = [UIColor blackColor];
    }
    return _endTimeLabel;
}

- (UISlider *)endTimeSlider {
    if (!_endTimeSlider) {
        _endTimeSlider = [[UISlider alloc] init];
    }
    return _endTimeSlider;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[UIButton alloc] init];
        [_confirmButton setTitle:NSLocalizedString(@"ipc_cloud_download", @"") forState:UIControlStateNormal];
        _confirmButton.layer.borderColor = [UIColor blackColor].CGColor;
        _confirmButton.layer.borderWidth = 1;
        [_confirmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return _confirmButton;
}

- (UIButton *)speedButton {
    if (!_speedButton) {
        _speedButton = [[UIButton alloc] initWithFrame:CGRectMake(APP_SCREEN_WIDTH - 80, APP_TOP_BAR_HEIGHT + VideoViewHeight - 36, 36, 20)];
        [_speedButton setTitle:@"1x" forState:UIControlStateNormal];
        _speedButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        _speedButton.layer.borderWidth = 1.0;
        _speedButton.layer.borderColor = [UIColor whiteColor].CGColor;
        _speedButton.layer.cornerRadius = 2.0;
    }
    return _speedButton;
}

- (TYDownloadingProgressView *)progressView {
    if (!_progressView) {
        _progressView = [TYDownloadingProgressView new];
    }
    return _progressView;
}

@end
