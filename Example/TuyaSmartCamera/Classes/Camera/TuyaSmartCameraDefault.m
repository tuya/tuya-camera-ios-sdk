//
//  TuyaSmartCameraDefault.m
//  CocoaAsyncSocket
//
//  Created by 傅浪 on 2019/2/13.
//

#import "TuyaSmartCameraDefault.h"
#import <TuyaSmartDeviceKit/TuyaSmartDeviceKit.h>

#define kTuyaSmartIPCConfigAPI @"tuya.m.ipc.config.get"
#define kTuyaSmartIPCConfigAPIVersion @"2.0"

@interface TuyaSmartCameraDefault () {
    BOOL _muteForPreview;
    BOOL _muteForPlayback;
    
    NSPointerArray *_observers;
}

@property (nonatomic, strong) NSString *devId;

@property (nonatomic, strong) id<TuyaSmartCameraType> camera;

@property (nonatomic, strong) _TuyaSmartVideoView *videoViewContainer;

@property (nonatomic, strong) NSMutableDictionary<NSString *, TYNumberArray *> *playbackDays;

@property (nonatomic, strong) TYDictArray *timeSlicesInCurrentDay;

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
        _observers = [NSPointerArray weakObjectsPointerArray];
        _videoViewContainer = [[_TuyaSmartVideoView alloc] initWithFrame:CGRectZero];
        
        _muteForPreview = YES;
        _muteForPlayback = YES;
    }
    return self;
}

- (void)dealloc {
    [self.camera destory];
}

- (void)addObserVer:(id<TuyaSmartCameraObserver>)observer {
    if (!observer) {
        return;
    }
    int index = -1;
    for (int i = 0; i < _observers.count; i++) {
        id obj = [_observers pointerAtIndex:i];
        if (obj == observer) {
            index = i;
            break;
        }
    }
    if (index == -1) {
        [_observers addPointer:(__bridge void * _Nullable)(observer)];
    }
}

- (void)removeObserver:(id<TuyaSmartCameraObserver>)observer {
    if (!observer) {
        return;
    }
    int index = -1;
    for (int i = 0; i < _observers.count; i++) {
        id obj = [_observers pointerAtIndex:i];
        if (obj == observer) {
            index = i;
            break;
        }
    }
    if (index != -1) {
        [_observers removePointerAtIndex:index];
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
        __weak typeof(self) weakself = self;
        [self createCamera:^{
            __strong typeof(weakself) self = weakself;
            [self.camera connect];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.videoViewContainer.renderView = self.camera.videoView;
            });
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
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
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
    if (!muted && self.isTalking && self.talkbackMode == TuyaSmartCameraTalkbackOneWay) {
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
    __weak typeof(self) weakself = self;
    id p2pType = [self.device.deviceModel.skills objectForKey:@"p2pType"];
    [[TuyaSmartRequest new] requestWithApiName:kTuyaSmartIPCConfigAPI postData:@{@"devId": self.devId} version:kTuyaSmartIPCConfigAPIVersion success:^(id result) {
        __strong typeof(weakself) self = weakself;
        [self audioAttributesMap:[result objectForKey:@"audioAttributes"]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            TuyaSmartCameraConfig *config = [TuyaSmartCameraFactory ipcConfigWithUid:[TuyaSmartUser sharedInstance].uid localKey:self.device.deviceModel.localKey configData:result];
            self.camera = [TuyaSmartCameraFactory cameraWithP2PType:p2pType config:config delegate:self];
            !complete?:complete();
        });
    } failure:^(NSError *error) {
        [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
            if ([obj respondsToSelector:@selector(camera:didOccurredError:)]) {
                [obj camera:self didOccurredError:TY_ERROR_CONNECT_FAILED];
            }
        }];
    }];
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
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidConnected:)]) {
            [obj cameraDidConnected:self];
        }
    }];
}

- (void)cameraDisconnected:(id<TuyaSmartCameraType>)camera {
    _connecting = NO;
    _connected = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidDisconnected:)]) {
            [obj cameraDidDisconnected:self];
        }
    }];
}

- (void)cameraDidConnectPlaybackChannel:(id<TuyaSmartCameraType>)camera {
    
}

- (void)cameraDidBeginPreview:(id<TuyaSmartCameraType>)camera {
    [self.camera getHD];
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStartPreview:)]) {
            [obj cameraDidStartPreview:self];
        }
    }];
}

- (void)cameraDidStopPreview:(id<TuyaSmartCameraType>)camera {
    _previewing = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStopPreview:)]) {
            [obj cameraDidStopPreview:self];
        }
    }];
}

- (void)cameraDidBeginPlayback:(id<TuyaSmartCameraType>)camera {
    _playbackPaused = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStatePlaying];
        }
    }];
}

- (void)cameraDidPausePlayback:(id<TuyaSmartCameraType>)camera {
    _playbackPaused = YES;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStatePaused];
        }
    }];
}

- (void)cameraDidResumePlayback:(id<TuyaSmartCameraType>)camera {
    _playbackPaused = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStatePlaying];
        }
    }];
}

- (void)cameraDidStopPlayback:(id<TuyaSmartCameraType>)camera {
    _playbacking = NO;
    _playbackPaused = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStateStop];
        }
    }];
}

- (void)cameraPlaybackDidFinished:(id<TuyaSmartCameraType>)camera {
    _playbacking = NO;
    _playbackPaused = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
            [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStateFinished];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveFirstFrame:(UIImage *)image {
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:didReceiveFirstFrame:)]) {
            [obj camera:self didReceiveFirstFrame:image];
        }
    }];
}

- (void)cameraDidBeginTalk:(id<TuyaSmartCameraType>)camera {
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStartTalk:)]) {
            [obj cameraDidStartTalk:self];
        }
    }];
}

- (void)cameraDidStopTalk:(id<TuyaSmartCameraType>)camera {
    _talking = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStopTalk:)]) {
            [obj cameraDidStopTalk:self];
        }
    }];
}

- (void)cameraSnapShootSuccess:(id<TuyaSmartCameraType>)camera {
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraSnapshootDidSaved:)]) {
            [obj cameraSnapshootDidSaved:self];
        }
    }];
}

- (void)cameraDidStartRecord:(id<TuyaSmartCameraType>)camera {
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStartRecording:)]) {
            [obj cameraDidStartRecording:self];
        }
    }];
}

- (void)cameraDidStopRecord:(id<TuyaSmartCameraType>)camera {
    _recording = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(cameraDidStopRecording:)]) {
            [obj cameraDidStopRecording:self];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveDefinitionState:(BOOL)isHd {
    _HD = isHd;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:definitionStateDidChanged:)]) {
            [obj camera:self definitionStateDidChanged:isHd];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera ty_didReceiveVideoFrame:(CMSampleBufferRef)sampleBuffer frameInfo:(TuyaSmartVideoFrameInfo)frameInfo {
    
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
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:muteStateDidChanged:)]) {
            [obj camera:self muteStateDidChanged:isMute];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didOccurredError:(TYCameraErrorCode)errCode {
    if (errCode == TY_ERROR_CONNECT_FAILED || errCode == TY_ERROR_CONNECT_DISCONNECT) {
        _connecting = NO;
        _connected = NO;
    }else if (errCode == TY_ERROR_START_PREVIEW_FAILED) {
        _previewing = NO;
    }else if (errCode == TY_ERROR_START_PLAYBACK_FAILED) {
        _playbacking = NO;
        [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
            if ([obj respondsToSelector:@selector(camera:playbackStateDidChagned:)]) {
                [obj camera:self playbackStateDidChagned:TuyaSmartCameraPlaybackStateStop];
            }
        }];
    }else if (errCode == TY_ERROR_PAUSE_PLAYBACK_FAILED) {
        _playbackPaused = NO;
    }else if (errCode == TY_ERROR_RECORD_FAILED) {
        _recording = NO;
    }else if (errCode == TY_ERROR_START_TALK_FAILED) {
        _talking = NO;
    }
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(camera:didOccurredError:)]) {
            [obj camera:self didOccurredError:errCode];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera resolutionDidChangeWidth:(NSInteger)width height:(NSInteger)height {
    [self.camera getHD];
}

#pragma mark - Accessor

- (UIView<TuyaSmartVideoViewType> *)videoView {
    return _videoViewContainer;
}

- (NSMutableDictionary<NSString *,TYNumberArray *> *)playbackDays {
    if (!_playbackDays) {
        _playbackDays = [NSMutableDictionary new];
    }
    return _playbackDays;
}

- (NSArray<id<TuyaSmartCameraObserver>> *)observers {
    return [_observers allObjects];
}

@end


@implementation _TuyaSmartVideoView

- (void)setRenderView:(UIView<TuyaSmartVideoViewType> *)renderView {
    _renderView = renderView;
    if (_renderView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addSubview:self.renderView];
        });
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.renderView.frame = self.bounds;
}



- (UIImage *)screenshot {
    return [self.renderView screenshot];
}

- (void)tuya_clear {
    [self.renderView tuya_clear];
}

- (void)tuya_setOffset:(CGPoint)offset {
    [self.renderView tuya_setOffset:offset];
}

- (void)tuya_setScaled:(float)scaled {
    [self.renderView tuya_setScaled:scaled];
}

- (void)setScaleToFill:(BOOL)scaleToFill {
    [self.renderView setScaleToFill:scaleToFill];
}

- (BOOL)scaleToFill {
    return self.renderView.scaleToFill;
}

@end
