//
//  TuyaSmartCameraDefault.m
//  CocoaAsyncSocket
//
//  Created by 傅浪 on 2019/2/13.
//

#import "TuyaSmartCameraDefault.h"
#import "TuyaSmartCameraFactory.h"
#import <TuyaSmartHomeKit/TuyaSmartKit.h>

#define kTuyaSmartIPCConfigAPI @"tuya.m.ipc.config.get"
#define kTuyaSmartIPCConfigAPIVersion @"1.0"

@interface TuyaSmartCameraDefault ()<TuyaSmartCameraDelegate> {
    BOOL _muteForPreview;
    BOOL _muteForPlayback;
    
    NSMutableSet *_observers;
}

@property (nonatomic, strong) NSString *devId;

@property (nonatomic, strong) id<TuyaSmartCameraType> camera;

@property (nonatomic, strong) NSMutableDictionary<NSString *, TYNumberArray *> *playbackDays;

@property (nonatomic, strong) TYDictArray *timeSlicesInCurrentDay;

@property (nonatomic, strong) TuyaSmartRequest *request;

@property (nonatomic, strong) NSString *lastPlaybackDayQueryMonth;

@property (nonatomic, copy) TYSuccessList getPlaybackDaysComplete;

@property (nonatomic, copy) TYSuccessList getRecordTimeSlicesComplete;

@end

@implementation TuyaSmartCameraDefault

- (instancetype)initWithDeviceId:(NSString *)devId {
    if (self = [super init]) {
        _devId = devId;
        _device = [TuyaSmartDevice deviceWithDeviceId:devId];
        _dpManager = [[TuyaSmartCameraDPManager alloc] initWithDeviceId:devId];
        _observers = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    [self.camera destory];
}

- (void)addObserVer:(id<TuyaSmartCameraObserver>)observer {
    [_observers addObject:observer];
}

- (void)removeObserver:(id<TuyaSmartCameraObserver>)observer {
    if ([_observers containsObject:observer]) {
        [_observers removeObject:observer];
    }
}

- (void)connect {
    if (self.isConnected || self.isConnecting) {
        return;
    }
    _connecting = YES;
    if (self.camera) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.camera connect];
        });
    }else {
        WEAKSELF_AT
        [self createCamera:^{
            [weakSelf_AT.camera connect];
        }];
    }
}

- (void)disConnect {
    [self stopPreview];
    [self stopPlayback];
    [self.camera disConnect];
}

- (void)startPreview {
    if (self.isPreviewing) {
        return;
    }
    if (self.isRecording) {
        [self.camera stopRecord];
    }
    if (self.isPlaybacking) {
        [self.camera stopPlayback];
    }
    [self.camera startPreview];
    _previewing = YES;
    self.playMode = TuyaSmartCameraPlayModePreview;
}

- (void)stopPreview {
    if (!self.isPreviewing) {
        return;
    }
    if (self.isRecording) {
        [self stopRecord];
    }
    if (self.isTalking) {
        [self stopTalk];
    }
    [self.camera stopPreview];
}

- (void)startPlaybackWithPlayTime:(NSInteger)playTime playbackSlice:(NSDictionary *)timeSlice {
    if (!timeSlice) { return; }
    NSNumber *startTime = [timeSlice objectForKey:kTuyaSmartTimeSliceStartTime];
    NSNumber *stopTime = [timeSlice objectForKey:kTuyaSmartTimeSliceStopTime];
    if (!startTime || !stopTime) {
        return;
    }
    if (self.isPreviewing) {
        [self stopPreview];
    }
    [self.camera startPlayback:playTime startTime:startTime.integerValue stopTime:stopTime.integerValue];
    _playbacking = YES;
    self.playMode = TuyaSmartCameraPlayModePlayback;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStateLoading];
        }
    }];
}

- (void)pausePlayback {
    if (self.isRecording) {
        [self.camera stopRecord];
    }
    [self.camera pausePlayback];
}

- (void)resumePlayback {
    if (self.isPlaybackPuased) {
        [self.camera resumePlayback];
    }
}

- (void)stopPlayback {
    if (!self.isPlaybacking) {
        return;
    }
    if (self.isRecording) {
        [self.camera stopRecord];
    }
    [self.camera stopPlayback];
}

- (void)playbackDaysInYear:(NSInteger)year month:(NSInteger)month complete:(void (^)(TYNumberArray *))complete {
    NSString *monthKey = [NSString stringWithFormat:@"%@-%@", @(year), @(month)];
    TYNumberArray *days = [self.playbackDays objectForKey:monthKey];
    if (days) {
        !complete?:complete(days);
    }else {
        self.getPlaybackDaysComplete = complete;
        [self getPlaybackDaysWithYear:year month:month];
    }
}

- (void)recordTimeSliceWithPlaybackDate:(TuyaSmartPlaybackDate *)date complete:(void(^)(TYDictArray *result))complete {
    NSString *monthKey = [NSString stringWithFormat:@"%@-%@", @(date.year), @(date.month)];
    TYNumberArray *days = [self.playbackDays objectForKey:monthKey];
    
    if (![days containsObject:@(date.day)] && ![TuyaSmartPlaybackDate isToday:date]) {
        !complete?:complete(@[]);
    }else {
        self.getRecordTimeSlicesComplete = complete;
        [self.camera queryRecordTimeSliceWithYear:date.year month:date.month day:date.day];
    }
}

- (void)startTalk {
    if (self.playMode == TuyaSmartCameraPlayModePreview) {
        if (!self.isMuted && self.talkbackMode == TuyaSmartCameraTalkbackOneWay) {
            self.muted = YES;
        }
        [self.camera startTalk];
        _talking = YES;
    }
}

- (void)stopTalk {
    if (self.isTalking) {
        [self.camera stopTalk];
    }
}

- (UIImage *)snapShoot {
    return [self.camera snapShoot];
}

- (void)startRecord {
    if (self.previewing || self.playbacking) {
        [self.camera startRecord];
        _recording = YES;
    }
}

- (void)stopRecord {
    if (self.isRecording) {
        [self.camera stopRecord];
        _recording = NO;
    }
}

- (void)setMuted:(BOOL)muted {
    if (self.isTalking && self.talkbackMode == TuyaSmartCameraTalkbackOneWay) {
        [self.camera stopTalk];
    }
    [self.camera enableMute:muted forPlayMode:self.playMode];
}

- (BOOL)isMuted {
    if (self.playMode == TuyaSmartCameraPlayModePreview) {
        return _muteForPreview;
    }else if (self.playMode == TuyaSmartCameraPlayModePlayback) {
        return _muteForPlayback;
    }
    return YES;
}

- (void)setHD:(BOOL)HD {
    if (self.previewing) {
        [self.camera enableHD:HD];
    }
}

#pragma mark - private

- (void)createCamera:(void(^)(void))complete {
    WEAKSELF_AT
    id p2pType = [self.device.deviceModel.skills objectForKey:@"p2pType"];
    [self.request requestWithApiName:kTuyaSmartIPCConfigAPI postData:@{@"devId": self.devId} version:kTuyaSmartIPCConfigAPIVersion success:^(id result) {
        [weakSelf_AT audioAttributesMap:[result objectForKey:@"audioAttributes"]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            TuyaSmartCameraConfig *config = [weakSelf_AT cameraConfigWithConfigData:result];
            weakSelf_AT.camera = [TuyaSmartCameraFactory cameraWithP2PType:p2pType config:config delegate:weakSelf_AT];
            !complete?:complete();
        });
    } failure:^(NSError *error) {
        [weakSelf_AT.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
            if ([obj respondsToSelector:@selector(camera:didOccurredError:)]) {
                [obj camera:weakSelf_AT didOccurredError:TY_ERROR_CONNECT_FAILED];
            }
        }];
    }];
}

- (TuyaSmartCameraConfig *)cameraConfigWithConfigData:(NSDictionary *)data {
    TuyaSmartCameraConfig *config = [TuyaSmartCameraConfig new];
    config.p2pId = [data objectForKey:@"p2pId"];
    config.password = [data objectForKey:@"password"];
    config.localKey = self.device.deviceModel.localKey;
    config.p2pConfig = [data objectForKey:@"p2pConfig"];
    return config;
}

- (void)audioAttributesMap:(NSDictionary *)attributes {
    __block BOOL supportSound = NO;
    __block BOOL supportTalk = NO;
    BOOL couldChangeAudioMode = NO;
    self.talkbackMode = TuyaSmartCameraTalkbackOneWay;
    if (!attributes) { return; }
    NSArray *hardwareCapability = [attributes objectForKey:@"hardwareCapability"];
    NSArray *callMode = [attributes objectForKey:@"callMode"];
    if (!hardwareCapability || hardwareCapability.count == 0) {
        return;
    }
    [hardwareCapability enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj integerValue] == 1) {
            supportSound = YES;
        }
        if ([obj integerValue] == 2) {
            supportTalk = YES;
        }
    }];
    
    if (!callMode || callMode.count == 0) {
        return;
    }
    
    if (callMode.count >= 2) {
        couldChangeAudioMode = YES;
    }else {
        couldChangeAudioMode = NO;
    }
    
    _isSupportInstantTalkback = couldChangeAudioMode;
}

- (void)getPlaybackDaysWithYear:(NSInteger)year month:(NSInteger)month {
    [self.camera queryRecordDaysWithYear:year month:month];
    self.lastPlaybackDayQueryMonth = [NSString stringWithFormat:@"%@-%@", @(year), @(month)];
}

#pragma mark - TuyaSmartCameraDelegate

- (void)cameraDidConnected:(id<TuyaSmartCameraType>)camera {
    _connecting = NO;
    _connected = YES;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidConnected:)]) {
            [obj cameraDidConnected:self];
        }
    }];
}

- (void)cameraDisconnected:(id<TuyaSmartCameraType>)camera {
    _connecting = NO;
    _connected = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidDisconnected:)]) {
            [obj cameraDidDisconnected:self];
        }
    }];
}

- (void)cameraDidConnectPlaybackChannel:(id<TuyaSmartCameraType>)camera {
    
}

- (void)cameraDidBeginPreview:(id<TuyaSmartCameraType>)camera {
    [self.camera getHD];
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStartPreview:)]) {
            [obj cameraDidStartPreview:self];
        }
    }];
}

- (void)cameraDidStopPreview:(id<TuyaSmartCameraType>)camera {
    _previewing = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStopPreview:)]) {
            [obj cameraDidStopPreview:self];
        }
    }];
}

- (void)cameraDidBeginPlayback:(id<TuyaSmartCameraType>)camera {
    _playbackPaused = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStatePlaying];
        }
    }];
}

- (void)cameraDidPausePlayback:(id<TuyaSmartCameraType>)camera {
    _playbackPaused = YES;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStatePaused];
        }
    }];
}

- (void)cameraDidResumePlayback:(id<TuyaSmartCameraType>)camera {
    _playbackPaused = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStatePlaying];
        }
    }];
}

- (void)cameraDidStopPlayback:(id<TuyaSmartCameraType>)camera {
    _playbacking = NO;
    _playbackPaused = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStateStop];
        }
    }];
}

- (void)cameraPlaybackDidFinished:(id<TuyaSmartCameraType>)camera {
    _playbacking = NO;
    _playbackPaused = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStateFinished];
        }
    }];
}

- (void)cameraDidReceiveFirstFrame:(id<TuyaSmartCameraType>)camera {
    
}

- (void)cameraDidBeginTalk:(id<TuyaSmartCameraType>)camera {
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStartTalk:)]) {
            [obj cameraDidStartTalk:self];
        }
    }];
}

- (void)cameraDidStopTalk:(id<TuyaSmartCameraType>)camera {
    _talking = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStopTalk:)]) {
            [obj cameraDidStopTalk:self];
        }
    }];
}

- (void)cameraSnapShootSuccess:(id<TuyaSmartCameraType>)camera {
    
}

- (void)cameraDidStartRecord:(id<TuyaSmartCameraType>)camera {
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStartRecording:)]) {
            [obj cameraDidStartRecording:self];
        }
    }];
}

- (void)cameraDidStopRecord:(id<TuyaSmartCameraType>)camera {
    _recording = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStopRecording:)]) {
            [obj cameraDidStopRecording:self];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveDefinitionState:(BOOL)isHd {
    _HD = isHd;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:definitionStateDidChanged:)]) {
            [obj camera:self definitionStateDidChanged:isHd];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveRecordDayQueryData:(NSArray<NSNumber *> *)days {
    if (self.lastPlaybackDayQueryMonth.length > 0) {
        [self.playbackDays setObject:days forKey:self.lastPlaybackDayQueryMonth];
        self.lastPlaybackDayQueryMonth = nil;
        if (self.getPlaybackDaysComplete) {
            self.getPlaybackDaysComplete(days);
            self.getPlaybackDaysComplete = nil;
        }
    }
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveTimeSliceQueryData:(NSArray<NSDictionary *> *)timeSlices {
    self.timeSlicesInCurrentDay = [timeSlices copy];
    if (self.getRecordTimeSlicesComplete) {
        self.getRecordTimeSlicesComplete(self.timeSlicesInCurrentDay);
        self.getRecordTimeSlicesComplete = nil;
    }
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveMuteState:(BOOL)isMute playMode:(TuyaSmartCameraPlayMode)playMode {
    if (playMode == TuyaSmartCameraPlayModePreview) {
        _muteForPreview = isMute;
    }else if (playMode == TuyaSmartCameraPlayModePlayback) {
        _muteForPlayback = isMute;
    }
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:muteStateDidChanged:)]) {
            [obj camera:self muteStateDidChanged:isMute];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didOccurredError:(TYCameraErrorCode)errCode {
    if (errCode == TY_ERROR_CONNECT_FAILED || errCode == TY_ERROR_CONNECT_DISCONNECT) {
        _connecting = NO;
        _connected = NO;
    }
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:didOccurredError:)]) {
            [obj camera:self didOccurredError:errCode];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera resolutionDidChangeWidth:(NSInteger)width height:(NSInteger)height {
    
}

- (void)camera:(id<TuyaSmartCameraType>)camera ty_didReceiveFrameData:(const char *)frameData dataSize:(unsigned int)size frameInfo:(TuyaSmartVideoFrameInfo)frameInfo {
    
}

#pragma mark - Accessor

- (UIView<TuyaSmartVideoViewType> *)videoView {
    if (self.camera) {
        return self.camera.videoView;
    }
    return nil;
}

- (TuyaSmartRequest *)request {
    if (!_request) {
        _request = [TuyaSmartRequest new];
    }
    return _request;
}

- (NSMutableDictionary<NSString *,TYNumberArray *> *)playbackDays {
    if (!_playbackDays) {
        _playbackDays = [NSMutableDictionary new];
    }
    return _playbackDays;
}

- (NSSet<id<TuyaSmartCameraObserver>> *)observers {
    return [_observers copy];
}

@end
