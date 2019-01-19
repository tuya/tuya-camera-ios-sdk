//
//  TuyaSmartCameraViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2018/12/24.
//  Copyright © 2018 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartCameraViewController.h"
#import "TuyaSmartControlModel.h"
#import "TuyaSmartControlCollectionViewCell.h"
#import <TuyaSmartCamera/TuyaSmartCameraFactory.h>
#import "NSDate+TuyaSmart.h"
#import <TuyaSmartHomeKit/TuyaSmartKit.h>

#define TUYA_SMART_CAMERA_ACTIVE_DP @"149"

@interface TuyaSmartCameraViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, TuyaSmartCameraDelegate, TuyaSmartDeviceDelegate>
@property (weak, nonatomic) IBOutlet UIView *videoViewContainer;
@property (weak, nonatomic) IBOutlet UICollectionView *controlCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *playbackDayLabel;
@property (weak, nonatomic) IBOutlet UITableView *playbackSliceTableView;
@property (weak, nonatomic) IBOutlet UIView *playbackView;

@property (nonatomic, strong) NSString *devId;
@property (nonatomic, strong) TuyaSmartRequest *request;
@property (nonatomic, strong) TuyaSmartDevice *device;
@property (nonatomic, strong) id<TuyaSmartCameraType> camera;
@property (nonatomic, strong) NSArray<NSNumber *> *playbackDays;
@property (nonatomic, strong) NSArray<NSDictionary *> *playbackSlices;
@property (nonatomic, strong) NSArray<TuyaSmartControlModel *> *controls;

@property (nonatomic, assign) TuyaSmartCameraPlayMode playMode;

@property (nonatomic, assign) NSInteger curentDay;

@property (nonatomic, assign) BOOL isConnected;

@property (nonatomic, assign) BOOL isPreviewing;

@property (nonatomic, assign) BOOL isPlaybacking;

@property (nonatomic, assign) BOOL isPlaybackPaused;

@property (nonatomic, assign) BOOL isTalking;

@property (nonatomic, assign) BOOL isRecording;

@property (nonatomic, assign) BOOL isMuted;

@end

@implementation TuyaSmartCameraViewController

- (void)dealloc {
    [self.camera destory];
}

- (instancetype)initWithDeviceId:(NSString *)devId {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.devId = devId;
        self.device = [TuyaSmartDevice deviceWithDeviceId:devId];
        self.device.delegate = self;
        self.isMuted = YES;
    }
    return self;
}

- (void)createCamera {
    id p2pType = [self.device.deviceModel.skills objectForKey:@"p2pType"];
    __weak typeof(self) weakSelf = self;
    [self.request requestWithApiName:@"tuya.m.ipc.config.get" postData:@{@"devId": self.devId} version:@"1.0" success:^(id result) {
        TuyaSmartCameraConfig *config = [TuyaSmartCameraConfig new];
        config.p2pId = [result objectForKey:@"p2pId"];
        config.password = [result objectForKey:@"password"];
        config.localKey = self.device.deviceModel.localKey;
        config.p2pConfig = [result objectForKey:@"p2pConfig"];
        weakSelf.camera = [TuyaSmartCameraFactory cameraWithP2PType:p2pType
                                                             config:config
                                                           delegate:self];
        
//        weakSelf.camera.isRecvFrame = YES;  // if you want decode video frame data by your self, uncomment this line
        [weakSelf startStream];
    } failure:^(NSError *error) {
        NSLog(@"get ipc config error: %@", error);
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.camera) {
        [self startStream];
    }else {
        [self createCamera];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isPreviewing) {
        [self previewAction];
    }
    if (self.isPlaybacking) {
        [self playbackAction];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.device.deviceModel.name;
    [self.controlCollectionView registerClass:[TuyaSmartControlCollectionViewCell class] forCellWithReuseIdentifier:@"control"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didEnterBackground {
    if (self.isPreviewing) {
        [self previewAction];
    }
    if (self.isPlaybacking) {
        [self playbackAction];
    }
    [self performSelector:@selector(disConnect) withObject:nil afterDelay:15];
}

- (void)willEnterForeground {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disConnect) object:nil];
    if (!self.isConnected) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self connect];
        });
    }else {
        if (self.playMode == TuyaSmartCameraPlayModePlayback) {
            [self playbackAction];
        }else {
            [self previewAction];
        }
    }
}

#pragma mark - collection view

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.controls.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TuyaSmartControlCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"control" forIndexPath:indexPath];
    TuyaSmartControlModel *controlModel = [self.controls objectAtIndex:indexPath.item];
    cell.textLabel.text = controlModel.controlName;
    if (controlModel.isSelected) {
        cell.backgroundColor = [UIColor redColor];
    }else {
        cell.backgroundColor = [UIColor grayColor];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    TuyaSmartControlModel *model = [self.controls objectAtIndex:indexPath.item];
    [model.target performSelector:NSSelectorFromString(model.action)];
}

#pragma mark - table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playbackSlices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playbackSlice"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"playbackSlice"];
    }
    NSDictionary *dict = [self.playbackSlices objectAtIndex:indexPath.row];
    NSDate *startDate = dict[kTuyaSmartTimeSliceStartDate];
    NSDate *stopDate = dict[kTuyaSmartTimeSliceStopDate];
    cell.textLabel.text = [self sliceTitleWithStartDate:startDate stopDate:stopDate];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *timeSlice = [self.playbackSlices objectAtIndex:indexPath.row];
    NSInteger startTime = [[timeSlice objectForKey:kTuyaSmartTimeSliceStartTime] integerValue];
    NSInteger stopTime = [[timeSlice objectForKey:kTuyaSmartTimeSliceStopTime] integerValue];
    if (self.isPreviewing) {
        [self previewAction];
    }
    self.controls[1].selected = YES;
    [self.controlCollectionView reloadData];
    [self.camera startPlayback:startTime startTime:startTime stopTime:stopTime];
    self.playbackView.hidden = YES;
}

#pragma mark - TuyaSmartDeviceDelegate

- (void)device:(TuyaSmartDevice *)device dpsUpdate:(NSDictionary *)dps {
    NSLog(@"dps did udpate: %@", dps);
    if ([dps objectForKey:TUYA_SMART_CAMERA_ACTIVE_DP]) {
        [self startStream];
    }
}

#pragma mark - Action
- (IBAction)prevDayAction:(id)sender {
    __block NSInteger index = -1;
    [self.playbackDays enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (_curentDay == obj.integerValue) {
            index = idx;
            *stop = YES;
        }
    }];
    if (index > 0) {
        _curentDay = [self.playbackDays objectAtIndex:index-1].integerValue;
        self.playbackDayLabel.text = [NSString stringWithFormat:@"%@-%@-%@", @([NSDate date].tuya_year), @([NSDate date].tuya_month), @(_curentDay)];
        [self.camera queryRecordTimeSliceWithYear:[NSDate date].tuya_year month:[NSDate date].tuya_month day:_curentDay];
    }
}

- (IBAction)nextDayAction:(id)sender {
    __block NSInteger index = -1;
    [self.playbackDays enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (_curentDay == obj.integerValue) {
            index = idx;
            *stop = YES;
        }
    }];
    if (index < self.playbackDays.count-1) {
        _curentDay = [self.playbackDays objectAtIndex:index+1].integerValue;
        self.playbackDayLabel.text = [NSString stringWithFormat:@"%@-%@-%@", @([NSDate date].tuya_year), @([NSDate date].tuya_month), @(_curentDay)];
        [self.camera queryRecordTimeSliceWithYear:[NSDate date].tuya_year month:[NSDate date].tuya_month day:_curentDay];
    }
}

- (IBAction)closePlaybackView:(id)sender {
    self.playbackView.hidden = YES;
}
#pragma mark - Camera Action

- (BOOL)isDeviceActive {
    id obj = [self.device.deviceModel.dps objectForKey:TUYA_SMART_CAMERA_ACTIVE_DP];
    if (obj) {
        return [obj boolValue];
    }
    return YES;
}

- (void)startStream {
    if (![self isDeviceActive]) {
        [self.device awakeDeviceWithSuccess:^{
            NSLog(@"publish awake command success");
        } failure:^(NSError *error) {
            NSLog(@"awake device error: %@", error);
        }];
        return;
    }
    
    if (!self.isConnected) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self connect];
        });
    }else {
        if (self.playMode == TuyaSmartCameraPlayModePlayback) {
            [self playbackAction];
        }else {
            [self previewAction];
        }
    }
}

- (void)connect {
    [self.camera connect];
}

- (void)previewAction {
    if (self.isPreviewing) {
        if (self.isRecording) {
            [self recordAction];
        }
        if (self.isTalking) {
            [self talkAction];
        }
        [self.camera stopPreview];
        self.controls.firstObject.selected = NO;
    }else {
        if (self.isPlaybacking) {
            [self playbackAction];
        }
        [self.camera startPreview];
        self.controls.firstObject.selected = YES;
    }
    [self.controlCollectionView reloadData];
}

- (void)playbackAction {
    if (self.isPlaybacking) {
        if (self.isRecording) {
            [self recordAction];
        }
        [self.camera stopPlayback];
        self.controls[1].selected = NO;
    }else {
        [self.camera queryRecordDaysWithYear:[NSDate date].tuya_year month:[NSDate date].tuya_month];
    }
    [self.controlCollectionView reloadData];
}

- (void)pausePlayback {
    if (self.isPlaybackPaused) {
        [self.camera resumePlayback];
        self.controls[2].selected = NO;
    }else {
        if (self.isRecording) {
            [self recordAction];
        }
        [self.camera pausePlayback];
        self.controls[2].selected = YES;
    }
    [self.controlCollectionView reloadData];
}

- (void)muteAction {
    if (self.isRecording) {
        return;
    }
    BOOL muted = !self.isMuted;
    [self.camera enableMute:muted forPlayMode:self.playMode];
    self.controls[3].selected = !muted;
    [self.controlCollectionView reloadData];
}

- (void)snapShoot {
    [self.camera snapShoot];
}

- (void)recordAction {
    if (self.isRecording) {
        [self.camera stopRecord];
        self.controls[5].selected = NO;
    }else {
        [self.camera startRecord];
        self.controls[5].selected = YES;
    }
    [self.controlCollectionView reloadData];
}

- (void)talkAction {
    if (self.isRecording) {
        return;
    }
    if (self.isTalking) {
        [self.camera stopTalk];
        self.controls[6].selected = NO;
    }else {
        [self.camera startTalk];
        self.controls[6].selected = YES;
    }
    [self.controlCollectionView reloadData];
}

- (void)disConnect {
    [self.camera disConnect];
}

- (void)slicesTableAction {
    self.playbackView.hidden = NO;
}

#pragma mark - TuyaSmartCameraDelegate

- (void)cameraDidConnected:(id<TuyaSmartCameraType>)camera {
    self.isConnected = YES;
    [self.camera enterPlayback];
    if (self.playMode == TuyaSmartCameraPlayModePlayback) {
        [self playbackAction];
    }else {
        [self previewAction];
    }
    NSLog(@"---didconnected");
}

- (void)cameraDisconnected:(id<TuyaSmartCameraType>)camera {
    self.isConnected = NO;
    NSLog(@"---disconnected");
}

- (void)cameraDidConnectPlaybackChannel:(id<TuyaSmartCameraType>)camera {
    NSLog(@"---didconnectedplayback");
}

- (void)cameraDidBeginPreview:(id<TuyaSmartCameraType>)camera {
    self.playMode = TuyaSmartCameraPlayModePreview;
    self.isPreviewing = YES;
    [self.videoViewContainer addSubview:self.camera.videoView];
    self.camera.videoView.frame = self.videoViewContainer.bounds;
    NSLog(@"---begin preview");
}

- (void)cameraDidStopPreview:(id<TuyaSmartCameraType>)camera {
    self.playMode = TuyaSmartCameraPlayModeNone;
    self.isPreviewing = NO;
    NSLog(@"---stop preview");
}

- (void)cameraDidBeginPlayback:(id<TuyaSmartCameraType>)camera {
    self.playMode = TuyaSmartCameraPlayModePlayback;
    self.isPlaybacking = YES;
    self.isPlaybackPaused = NO;
    [self.videoViewContainer addSubview:self.camera.videoView];
    self.camera.videoView.frame = self.videoViewContainer.bounds;
    NSLog(@"---begin playback");
}

- (void)cameraDidPausePlayback:(id<TuyaSmartCameraType>)camera {
    self.isPlaybackPaused = YES;
    NSLog(@"---pause playback");
}

- (void)cameraDidResumePlayback:(id<TuyaSmartCameraType>)camera {
    self.isPlaybackPaused = NO;
    NSLog(@"---resume playback");
}

- (void)cameraDidStopPlayback:(id<TuyaSmartCameraType>)camera {
    self.playMode = TuyaSmartCameraPlayModeNone;
    self.isPlaybacking = NO;
    self.isPlaybackPaused = NO;
    NSLog(@"---stop playback");
}

- (void)cameraPlaybackDidFinished:(id<TuyaSmartCameraType>)camera {
    self.playMode = TuyaSmartCameraPlayModeNone;
    self.isPlaybacking = NO;
    self.isPlaybackPaused = NO;
    NSLog(@"---playback finished");
}

- (void)cameraDidReceiveFirstFrame:(id<TuyaSmartCameraType>)camera {
    NSLog(@"---receive first frame");
}

- (void)cameraDidBeginTalk:(id<TuyaSmartCameraType>)camera {
    self.isTalking = YES;
    self.controls[6].selected = self.isTalking;
    [self.controlCollectionView reloadData];
    NSLog(@"---begin talk");
}

- (void)cameraDidStopTalk:(id<TuyaSmartCameraType>)camera {
    self.isTalking = NO;
    self.controls[6].selected = self.isTalking;
    [self.controlCollectionView reloadData];
    NSLog(@"---stop talk");
}

- (void)camearaSnapShootSuccess:(id<TuyaSmartCameraType>)camera {
    NSLog(@"---snap shoot success");
}

- (void)cameraDidStartRecord:(id<TuyaSmartCameraType>)camera {
    self.isRecording = YES;
    self.controls[5].selected = self.isRecording;
    [self.controlCollectionView reloadData];
    NSLog(@"---start Record");
}

- (void)cameraDidStopRecord:(id<TuyaSmartCameraType>)camera {
    self.isRecording = NO;
    self.controls[5].selected = self.isRecording;
    [self.controlCollectionView reloadData];
    NSLog(@"---stop record");
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveDefinitionStatus:(BOOL)isHd {
    NSLog(@"---receive HD state: %d", isHd);
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveRecordDayQueryData:(NSArray<NSNumber *> *)days {
    NSLog(@"---receive record days: %@", days);
    self.playbackDays = days;
    _curentDay = days.lastObject.integerValue;
    self.playbackDayLabel.text = [NSString stringWithFormat:@"%@-%@-%@", @([NSDate date].tuya_year), @([NSDate date].tuya_month), @(_curentDay)];
    [self.camera queryRecordTimeSliceWithYear:[NSDate date].tuya_year month:[NSDate date].tuya_month day:_curentDay];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveTimeSliceQueryData:(NSArray<NSDictionary *> *)timeSlices {
    NSLog(@"---receive time slice: %@", timeSlices);
    self.playbackSlices = timeSlices;
    self.playbackView.hidden = NO;
    [self.playbackSliceTableView reloadData];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveMuteState:(BOOL)isMute playMode:(TuyaSmartCameraPlayMode)playMode {
    self.isMuted = isMute;
    self.controls[3].selected = !self.isMuted;
    [self.controlCollectionView reloadData];
    NSLog(@"---receive mute state: %d", isMute);
}

- (void)camera:(id<TuyaSmartCameraType>)camera didOccurredError:(TYCameraErrorCode)errCode {
    if (errCode == TY_ERROR_START_PREVIEW_FAILED) {
        self.isPreviewing = NO;
        self.controls.firstObject.selected = NO;
    }
    if (errCode == TY_ERROR_START_PLAYBACK_FAILED) {
        self.isPlaybacking = NO;
        self.controls[1].selected = NO;
    }
    if (errCode == TY_ERROR_START_TALK_FAILED) {
        self.isTalking = NO;
        self.controls[6].selected = NO;
    }
    if (errCode == TY_ERROR_RECORD_FAILED) {
        self.isRecording = NO;
        self.controls[5].selected = NO;
    }
    if (errCode == TY_ERROR_CONNECT_FAILED || errCode == TY_ERROR_CONNECT_DISCONNECT) {
        self.isConnected = NO;
    }
    NSLog(@"---occurred error: %u", errCode);
    [self.controlCollectionView reloadData];
}

- (void)camera:(id<TuyaSmartCameraType>)camera resolutionDidChangeWidth:(NSInteger)width height:(NSInteger)height {
    NSLog(@"---resolution changed: %ld x %ld", width, height);
}

- (void)camera:(id<TuyaSmartCameraType>)camera ty_didReceiveFrameData:(const char *)frameData DataSize:(unsigned int)size FrmInfo:(NSData *)infoData {
    NSLog(@"------------");
}

#pragma mark - util

- (NSString *)sliceTitleWithStartDate:(NSDate *)startDate stopDate:(NSDate *)stopDate {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm";
    });
    NSString *start = [formatter stringFromDate:startDate];
    NSString *stop = [formatter stringFromDate:stopDate];
    return [NSString stringWithFormat:@"%@-%@", start, stop];
}

#pragma mark - Accessor

- (NSArray<TuyaSmartControlModel *> *)controls {
    if (!_controls) {
        NSArray *controlNames = @[@"Live Video", @"Playback", @"Pause", @"sound", @"screenshot", @"Record", @"Talk", @"Slices"];
        NSArray *actions = @[@"previewAction", @"playbackAction", @"pausePlayback", @"muteAction", @"snapShoot", @"recordAction", @"talkAction", @"slicesTableAction"];
        NSMutableArray *temp = [NSMutableArray array];
        [controlNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            TuyaSmartControlModel *model = [[TuyaSmartControlModel alloc] initWithName:obj target:self action:actions[idx]];
            [temp addObject:model];
        }];
        _controls = [temp copy];
    }
    return _controls;
}

- (TuyaSmartRequest *)request {
    if (!_request) {
        _request = [TuyaSmartRequest new];
    }
    return _request;
}

@end
