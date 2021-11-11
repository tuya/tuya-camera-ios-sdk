//
//  TuyaSmartCamera.m
//  TuyaSmartCamera_Example
//
//  Copyright (c) 2014-2021 Tuya Inc. (https://developer.tuya.com/)

#import "TuyaSmartCamera.h"
#import <TuyaSmartDeviceKit/TuyaSmartDeviceKit.h>
#import "TuyaSmartCameraService.h"
#import "TYPlaybackImageDownloadManager.h"

#define kTuyaSmartIPCConfigAPI @"tuya.m.rtc.session.init"
#define kTuyaSmartIPCConfigAPIVersion @"1.0"

#define kCallBackKeyConnect     @"connect"
#define kCallBackKeyPreview     @"preview"
#define kCallBackKeyPlayback    @"playback"
#define kCallBackKeyPause       @"pause"
#define kCallBackKeyResume      @"resume"
#define kCallBackKeyTalk        @"talk"
#define kCallBackKeySnapShot    @"snapShot"
#define kCallBackKeyRecord      @"record"
#define kCallBackKeyMute        @"mute"
#define kCallBackKeyHD          @"HD"

@interface _TuyaSmartVideoView : UIView <TuyaSmartVideoViewType>

@property (nonatomic, strong) UIView<TuyaSmartVideoViewType> *renderView;


@end

@interface _TuyaSmartCallback : NSObject

@property (nonatomic, copy) IPCVoidBlock success;

@property (nonatomic, copy) IPCErrorBlock failure;

+ (instancetype)callbackWithSuccess:(IPCVoidBlock)success failure:(IPCErrorBlock)failure;

- (void)callSuccess;

- (void)callFailure:(NSError *)error;

@end

@interface TuyaSmartCamera ()<TuyaSmartCameraDelegate> {
    BOOL _muteForPreview;
    BOOL _muteForPlayback;
    
    BOOL _lastMuted;
    
    NSPointerArray *_observers;
}

@property (nonatomic, strong) NSString *devId;

@property (nonatomic, strong) id<TuyaSmartCameraType> camera;

@property (nonatomic, strong) TYPlaybackImageDownloadManager *downloadManager;

@property (nonatomic, strong) _TuyaSmartVideoView *videoViewContainer;

@property (nonatomic, strong) NSMutableDictionary<NSString *, TYNumberArray *> *playbackDays;

@property (nonatomic, strong) TYDictArray *timeSlicesInCurrentDay;

@property (nonatomic, strong) NSString *lastPlaybackDayQueryMonth;

@property (nonatomic, copy) TYSuccessList getPlaybackDaysComplete;

@property (nonatomic, copy) TYSuccessList getRecordTimeSlicesComplete;

@property (nonatomic, strong) NSMutableDictionary<NSString *,_TuyaSmartCallback *> *callbacks;

@property (nonatomic, assign) NSInteger videoNum;

@end

@implementation TuyaSmartCamera

- (instancetype)initWithDeviceId:(NSString *)devId {
    if (self = [super init]) {
        _devId = devId;
        _device = [TuyaSmartDevice deviceWithDeviceId:devId];
        _dpManager = [[TuyaSmartCameraDPManager alloc] initWithDeviceId:devId];
        _downloadManager = [TYPlaybackImageDownloadManager new];
        _observers = [NSPointerArray weakObjectsPointerArray];
        _callbacks = [NSMutableDictionary new];
        
        _muteForPreview = YES;
        _muteForPlayback = YES;
        
        _videoViewContainer = [[_TuyaSmartVideoView alloc] initWithFrame:CGRectZero];
        // 默认两路码流
        _videoNum = 2;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:[AVAudioSession sharedInstance]];
    }
    return self;
}

- (void)dealloc {
    [self.callbacks removeAllObjects];
    [self.camera destory];
}

- (NSArray<id<TuyaSmartCameraObserver>> *)observers {
    return [_observers allObjects];
}

- (void)addObserver:(id<TuyaSmartCameraObserver>)observer {
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

- (UIView<TuyaSmartVideoViewType> *)videoView {
    return _videoViewContainer;
}

- (void)connect:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    if (self.isConnected || self.isConnecting) {
        return;
    }
    _connecting = YES;
    _callbacks[kCallBackKeyConnect] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
//    if (self.camera) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [self.camera connect];
//        });
//    }else {
        __weak typeof(self) weakself = self;
        [self createCamera:^(NSError *error) {
            __strong typeof(weakself) self = weakself;
            if (error) {
                self.connecting = NO;
                [self _taskFailureWithKey:kCallBackKeyConnect error:error];
            }else {
                [self.camera connect];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.videoViewContainer.renderView = self.camera.videoView;
                });
            }
        }];
//    }
}

- (void)disConnect {
    [self.camera.videoView stopPlay];
    [self stopPreview];
    [self stopPlayback];
    [self.camera disConnect];
}

- (void)startPreview:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    [self stopPlayback];
    [self.camera startPreview];
    _previewing = YES;
    self.playMode = TuyaSmartCameraPlayModePreview;
    _callbacks[kCallBackKeyPreview] = [_TuyaSmartCallback callbackWithSuccess:success failure:false];
    [self enableMute:self.isMuted success:nil failure:nil];
}

- (void)stopPreview {
    [self.camera.videoView stopPlay];
    [_callbacks removeObjectForKey:kCallBackKeyPreview];
    [self stopRecord:nil failure:nil];
    [self stopTalk];
    [self.camera stopPreview];
    self.playMode = TuyaSmartCameraPlayModeNone;
}

- (void)startPlaybackWithPlayTime:(NSInteger)playTime playbackSlice:(NSDictionary *)timeSlice success:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    if (!timeSlice) { return; }
    NSNumber *startTime = [timeSlice objectForKey:kTuyaSmartTimeSliceStartTime];
    NSNumber *stopTime = [timeSlice objectForKey:kTuyaSmartTimeSliceStopTime];
    if (!startTime || !stopTime) {
        return;
    }
    if (self.isPreviewing) {
        [self stopPreview];
    }
    _callbacks[kCallBackKeyPlayback] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
    [self.camera startPlayback:playTime startTime:startTime.integerValue stopTime:stopTime.integerValue];
    _playbacking = YES;
    self.playMode = TuyaSmartCameraPlayModePlayback;
    [self enableMute:self.isMuted success:nil failure:nil];
}

- (void)pausePlayback:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    [self stopRecord:nil failure:nil];
    _callbacks[kCallBackKeyPause] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
    [self.camera pausePlayback];
}

- (void)resumePlayback:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    if (!self.isPlaybackPuased) {
        return;
    }
    _callbacks[kCallBackKeyResume] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
    [self.camera resumePlayback];
}

- (void)stopPlayback {
    [self.camera.videoView stopPlay];
    [_callbacks removeObjectForKey:kCallBackKeyPlayback];
    [_callbacks removeObjectForKey:kCallBackKeyPause];
    [_callbacks removeObjectForKey:kCallBackKeyResume];
    [self stopRecord:nil failure:nil];
    [self.camera stopPlayback];
    self.playMode = TuyaSmartCameraPlayModeNone;
}

- (void)setPlaybackSpeed:(TuyaSmartCameraPlaybackSpeed)speed callback:(void(^)(int errCode))callback {
    [self.camera setPlaybackSpeed:speed response:callback];
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

- (void)requestTimeSliceWithPlaybackDate:(TuyaSmartPlaybackDate *)date complete:(void(^)(TYDictArray *result))complete {
    NSString *monthKey = [NSString stringWithFormat:@"%@-%@", @(date.year), @(date.month)];
    TYNumberArray *days = [self.playbackDays objectForKey:monthKey];
    
    if (![days containsObject:@(date.day)] && ![TuyaSmartPlaybackDate isToday:date]) {
        !complete?:complete(@[]);
    }else {
        self.getRecordTimeSlicesComplete = complete;
        [self.camera queryRecordTimeSliceWithYear:date.year month:date.month day:date.day];
    }
}

- (void)downloadThumbnailsWithTimeSlice:(NSDictionary *)timeSlice complete:(TYPlaybackImageDownloadCallback)complete {
    if (!complete) {
        return;
    }
    NSString *fileName = [[timeSlice[kTuyaSmartTimeSliceStartTime] stringValue] stringByAppendingPathExtension:@"jpg"];
    NSString *directoryPath = [[TuyaSmartCameraService sharedService] thumbnailDirectoryForDevice:self.devId];
    NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
    
    [self.downloadManager downloadThumbnailsWithTimeSlice:timeSlice filePath:filePath callback:complete];
}

- (void)downloadPlaybackVideoWithStartTime:(NSInteger)startTime endTime:(NSInteger)endTime success:(void(^)(NSString *filePath))success progress:(void(^)(int progress))progress failure:(void(^)(int errCode))failure {
    NSString *filePath = [self videoTempPathForDevice:self.devId];
    [self.camera startDownloadPlaybackVideoWithStartTime:startTime endTime:endTime filePath:filePath success:^{
        !success?:success(filePath);
    } progress:progress failure:failure];
}

- (void)cancelDownloadPlayback {
    [self.camera stopDownloadPlaybackVideo];
}

- (void)deletePlaybackVideoWithDate:(TuyaSmartPlaybackDate *)date callback:(void(^)(int errCode))callback {
    [self.camera deletePlayBackVideosWithYear:date.year month:date.month day:date.day callback:callback];
}

- (void)startTalk:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    if (self.playMode == TuyaSmartCameraPlayModePreview) {
        _callbacks[kCallBackKeyTalk] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
        [self.camera startTalk];
        _talking = YES;
    }
}

- (void)stopTalk {
    if (self.isTalking) {
        [_callbacks removeObjectForKey:kCallBackKeyTalk];
        [self.camera stopTalk];
        _talking = NO;
    }
}

- (UIImage *)snapShoot:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    _callbacks[kCallBackKeySnapShot] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
    return [self.camera snapShoot];
}

- (void)startRecord:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    if (self.isRecording) {
        return;
    }
    if (self.previewing || self.playbacking) {
        _callbacks[kCallBackKeyRecord] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
        [self.camera startRecord];
        _recording = YES;
    }
}

- (void)stopRecord:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    if (self.isRecording) {
        _callbacks[kCallBackKeyRecord] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
        [self.camera stopRecord];
    }
}

- (void)enableMute:(BOOL)isMute success:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    _callbacks[kCallBackKeyMute] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
    [self.camera enableMute:isMute forPlayMode:self.playMode];
}

- (void)enableHD:(BOOL)isHD success:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    if (self.previewing) {
        _callbacks[kCallBackKeyHD] = [_TuyaSmartCallback callbackWithSuccess:success failure:failure];
        [self.camera enableHD:isHD];
    }
}

- (BOOL)isMuted {
    if (self.playMode == TuyaSmartCameraPlayModePreview) {
        return _muteForPreview;
    }else if (self.playMode == TuyaSmartCameraPlayModePlayback) {
        return _muteForPlayback;
    }
    return YES;
}

- (TuyaSmartCameraTalkbackMode)talkbackMode {
    return TuyaSmartCameraTalkbackTwoWay;
}

- (id)jsonSerializationWithJsonStr:(NSString *)jsonStr {
    if (!jsonStr) {
        return nil;
    }
    NSError *error;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    return error ? nil : obj;
}

- (void)handleVideoNumberWithResult:(id)result {
    id skillsJSON = [result objectForKey:@"skill"];
    id skills = [self jsonSerializationWithJsonStr:skillsJSON];
    if ([skills isKindOfClass:[NSDictionary class]]) {
        NSDictionary *skillsDic = (NSDictionary *)skills;
        if (skillsDic) {
            id dataValue = [skillsDic objectForKey:@"video_num"];
            if ([dataValue respondsToSelector:@selector(integerValue)]) {
                NSInteger videoNum = [dataValue integerValue];
                self.videoNum = videoNum;
            }
        }
    }
}

#pragma mark - private

- (NSString *)videoTempPathForDevice:(NSString *)devId {
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.mp4", [TYCameraUtil md5WithString:devId], [NSDate new]];
    return [cachePath stringByAppendingPathComponent:fileName];
}

- (void)createCamera:(IPCErrorBlock)complete {
    __weak typeof(self) weakself = self;
    id p2pType = [self.device.deviceModel.skills objectForKey:@"p2pType"];
    TuyaSmartRequest *request = [TuyaSmartRequest new];
    [request requestWithApiName:kTuyaSmartIPCConfigAPI postData:@{@"devId": self.devId} version:kTuyaSmartIPCConfigAPIVersion success:^(id result) {
        __strong typeof(weakself) self = weakself;
        [self handleVideoNumberWithResult:result];
        [self audioAttributesMap:[result objectForKey:@"audioAttributes"]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            TuyaSmartCameraConfig *config = [TuyaSmartCameraFactory ipcConfigWithUid:[TuyaSmartUser sharedInstance].uid localKey:self.device.deviceModel.localKey configData:result];
            config.traceId = @"";
            self.camera = [TuyaSmartCameraFactory cameraWithP2PType:p2pType config:config delegate:self];
            self.camera.autoRender = NO;
            self.downloadManager.camera = self.camera;
            !complete?:complete(nil);
        });
        
    } failure:^(NSError *error) {
        !complete?:complete(error);
    }];
}

- (void)audioAttributesMap:(NSDictionary *)attributes {
    __block BOOL supportSound = NO;
    __block BOOL supportTalk = NO;
    BOOL couldChangeAudioMode = NO;
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
    
    TuyaSmartCameraTalkbackMode mode = [[TuyaSmartCameraService sharedService] audioModeForCamera:self.devId];
    if (mode == TuyaSmartCameraTalkbackNone) {
        mode = [callMode.firstObject integerValue];
    }
    mode = mode > TuyaSmartCameraTalkbackTwoWay ? TuyaSmartCameraTalkbackNone : mode;
    [[TuyaSmartCameraService sharedService] setAudioMode:mode forCamera:self.devId];
    _isSupportInstantTalkback = couldChangeAudioMode;
    _isSupportTalk = supportTalk;
    _isSupportSound = supportSound;
}

- (void)_taskSuccessWithKey:(NSString *)key {
    _TuyaSmartCallback *callback = [_callbacks objectForKey:key];
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [callback callSuccess];
        [self.callbacks removeObjectForKey:key];
    });
}

- (void)_taskFailureWithKey:(NSString *)key error:(NSError *)error {
    _TuyaSmartCallback *callback = [_callbacks objectForKey:key];
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [callback callFailure:error];
        [self.callbacks removeObjectForKey:key];
    });
}

- (void)getPlaybackDaysWithYear:(NSInteger)year month:(NSInteger)month {
    [self.camera queryRecordDaysWithYear:year month:month];
    self.lastPlaybackDayQueryMonth = [NSString stringWithFormat:@"%@-%@", @(year), @(month)];
}

#pragma mark - TuyaSmartCameraDelegate

- (void)cameraDidConnected:(id<TuyaSmartCameraType>)camera {
    [self.camera enterPlayback];
    _connecting = NO;
    _connected = YES;
    [self _taskSuccessWithKey:kCallBackKeyConnect];
}

- (void)cameraDisconnected:(id<TuyaSmartCameraType>)camera {
    _connecting = NO;
    _connected = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL * stop) {
        if ([obj respondsToSelector:@selector(cameraDidDisconnected:)]) {
            [obj cameraDidDisconnected:self];
        }
    }];
}

- (void)cameraDidConnectPlaybackChannel:(id<TuyaSmartCameraType>)camera {
    
}

- (void)cameraDidBeginPreview:(id<TuyaSmartCameraType>)camera {
    [self.camera getHD];
    [self _taskSuccessWithKey:kCallBackKeyPreview];
    [self.camera.videoView startPlay];
}

- (void)cameraDidStopPreview:(id<TuyaSmartCameraType>)camera {
    _previewing = NO;
}

- (void)cameraDidBeginPlayback:(id<TuyaSmartCameraType>)camera {
    _playbackPaused = NO;
    [self _taskSuccessWithKey:kCallBackKeyPlayback];
    [self.camera.videoView startPlay];
}

- (void)cameraDidPausePlayback:(id<TuyaSmartCameraType>)camera {
    _playbackPaused = YES;
    [self _taskSuccessWithKey:kCallBackKeyPause];
}

- (void)cameraDidResumePlayback:(id<TuyaSmartCameraType>)camera {
    _playbackPaused = NO;
    [self _taskSuccessWithKey:kCallBackKeyResume];
}

- (void)cameraDidStopPlayback:(id<TuyaSmartCameraType>)camera {
    _playbacking = NO;
    _playbackPaused = NO;
}

- (void)cameraPlaybackDidFinished:(id<TuyaSmartCameraType>)camera {
    _playbacking = NO;
    _playbackPaused = NO;
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL * stop) {
        if ([obj respondsToSelector:@selector(cameraPlaybackDidFinished:)]) {
            [obj cameraPlaybackDidFinished:self];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveFirstFrame:(UIImage *)image {
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL * stop) {
        if ([obj respondsToSelector:@selector(camera:didReceiveFirstFrame:)]) {
            [obj camera:self didReceiveFirstFrame:image];
        }
    }];
}

- (void)cameraDidBeginTalk:(id<TuyaSmartCameraType>)camera {
    [self _taskSuccessWithKey:kCallBackKeyTalk];
}

- (void)cameraDidStopTalk:(id<TuyaSmartCameraType>)camera {
    _talking = NO;
}

- (void)cameraSnapShootSuccess:(id<TuyaSmartCameraType>)camera {
    [self _taskSuccessWithKey:kCallBackKeySnapShot];
}

- (void)cameraDidStartRecord:(id<TuyaSmartCameraType>)camera {
    [self _taskSuccessWithKey:kCallBackKeyRecord];
}

- (void)cameraDidStopRecord:(id<TuyaSmartCameraType>)camera {
    _recording = NO;
    [self _taskSuccessWithKey:kCallBackKeyRecord];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveDefinitionState:(BOOL)isHd {
    _HD = isHd;
    [self _taskSuccessWithKey:kCallBackKeyHD];
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL * stop) {
        if ([obj respondsToSelector:@selector(camera:didReceiveDefinitionState:)]) {
            [obj camera:self didReceiveDefinitionState:isHd];
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
    [self _taskSuccessWithKey:kCallBackKeyMute];
    
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL * stop) {
        if ([obj respondsToSelector:@selector(camera:didReceiveMuteState:)]) {
            [obj camera:self didReceiveMuteState:isMute];
        }
    }];
}

- (void)camera:(id<TuyaSmartCameraType>)camera didOccurredErrorAtStep:(TYCameraErrorCode)errStepCode specificErrorCode:(NSInteger)errorCode {
    if (errStepCode == TY_ERROR_CONNECT_FAILED || errStepCode == TY_ERROR_CONNECT_DISCONNECT) {
        _connecting = NO;
        _connected = NO;
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"ipc_errmsg_device_unavailable", @"")}];
        [self _taskFailureWithKey:kCallBackKeyConnect error:error];
    }
    else if (errStepCode == TY_ERROR_START_PREVIEW_FAILED) {
        _previewing = NO;
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"ipc_errmsg_preview_failed", nil)}];
        [self _taskFailureWithKey:kCallBackKeyPreview error:error];
    }
    else if (errStepCode == TY_ERROR_START_PLAYBACK_FAILED) {
        _playbacking = NO;
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"ipc_errmsg_record_play_failed", @"")}];
        [self _taskFailureWithKey:kCallBackKeyPlayback error:error];
    }
    else if (errStepCode == TY_ERROR_PAUSE_PLAYBACK_FAILED) {
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"ipc_errmsg_record_pause_failed", @"")}];
        [self _taskFailureWithKey:kCallBackKeyPause error:error];
    }
    else if (errStepCode == TY_ERROR_RESUME_PLAYBACK_FAILED) {
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"ipc_errmsg_record_play_failed", @"")}];
        [self _taskFailureWithKey:kCallBackKeyResume error:error];
    }
    else if (errStepCode == TY_ERROR_START_TALK_FAILED) {
        _talking = NO;
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"ipc_errmsg_mic_failed", nil)}];
        [self _taskFailureWithKey:kCallBackKeyTalk error:error];
    }
    else if (errStepCode == TY_ERROR_SNAPSHOOT_FAILED) {
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"fail", @"")}];
        [self _taskFailureWithKey:kCallBackKeySnapShot error:error];
    }
    else if (errStepCode == TY_ERROR_RECORD_FAILED) {
        _recording = NO;
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"ipc_errmsg_record_failed", @"")}];
        [self _taskFailureWithKey:kCallBackKeyRecord error:error];
    }
    else if (errStepCode == TY_ERROR_ENABLE_MUTE_FAILED) {
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"ipc_errmsg_speaker_failed", @"")}];
        [self _taskFailureWithKey:kCallBackKeyMute error:error];
    }
    else if (errStepCode == TY_ERROR_ENABLE_HD_FAILED) {
        NSError *error = [NSError errorWithDomain:@"com.ipc.tuya" code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"ipc_errmsg_change_definition_failed", @"")}];
        [self _taskFailureWithKey:kCallBackKeyHD error:error];
    }
}

- (void)camera:(id<TuyaSmartCameraType>)camera didOccurredError:(TYCameraErrorCode)errCode {
    [self camera:camera didOccurredErrorAtStep:errCode specificErrorCode:-1];
}

- (void)camera:(id<TuyaSmartCameraType>)camera resolutionDidChangeWidth:(NSInteger)width height:(NSInteger)height {
    [self.camera getHD];
    _videoFrameSize = CGSizeMake(width, height);
}

- (void)camera:(id<TuyaSmartCameraType>)camera ty_didReceiveVideoFrame:(CMSampleBufferRef)sampleBuffer frameInfo:(TuyaSmartVideoFrameInfo)frameInfo {
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)sampleBuffer;
    [self.camera.videoView displayPixelBuffer:pixelBuffer];
    
    [self.observers enumerateObjectsUsingBlock:^(id<TuyaSmartCameraObserver> obj, NSUInteger idx, BOOL * stop) {
        if ([obj respondsToSelector:@selector(camera:didReceiveVideoFrame:frameInfo:)]) {
            [obj camera:self didReceiveVideoFrame:sampleBuffer frameInfo:frameInfo];
        }
    }];
}

#pragma mark - AudioSession implementations
//来电话声音恢复
- (void)handleInterruption:(NSNotification *)notification {
    NSInteger type = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        _lastMuted = self.isMuted; // 记录上次状态
        if (!self.isMuted) {//来电之前不是静音，这时候要暂时静音
            [self enableMute:YES success:nil failure:nil];
        }
    } else if (type == AVAudioSessionInterruptionTypeEnded) {
        if (!_lastMuted) {//来电之前没有静音，此时要恢复声音
            [self enableMute:NO success:nil failure:nil];
            _lastMuted = YES;//恢复默认值
        }
    }
}

- (NSMutableDictionary<NSString *,TYNumberArray *> *)playbackDays {
    if (!_playbackDays) {
        _playbackDays = [NSMutableDictionary new];
    }
    return _playbackDays;
}

@end


@implementation _TuyaSmartCallback

+ (instancetype)callbackWithSuccess:(IPCVoidBlock)success failure:(IPCErrorBlock)failure {
    _TuyaSmartCallback *callback = [_TuyaSmartCallback new];
    callback.success = success;
    callback.failure = failure;
    return callback;
}

- (void)callSuccess {
    !_success?:_success();
    [self destory];
}

- (void)callFailure:(NSError *)error {
    !_failure?:_failure(error);
    [self destory];
}

- (void)destory {
    self.success = nil;
    self.failure = nil;
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
