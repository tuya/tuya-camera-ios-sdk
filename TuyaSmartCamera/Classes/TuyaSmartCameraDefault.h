//
//  TuyaSmartCameraDefault.h
//  CocoaAsyncSocket
//
//  Created by 傅浪 on 2019/2/13.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TuyaSmartCameraType.h"
#import "TuyaSmartPlaybackDate.h"
#import "TuyaSmartCameraDPManager.h"

typedef NS_ENUM(NSUInteger, TuyaSmartCameraTalkbackMode) {
    TuyaSmartCameraTalkbackOneWay,
    TuyaSmartCameraTalkbackTwoWay
};

typedef NS_ENUM(NSUInteger, TuyaSmartCameraPlaybackState) {
    TuyaSmartCameraPlaybackStateStop,
    TuyaSmartCameraPlaybackStateLoading,
    TuyaSmartCameraPlaybackStatePlaying,
    TuyaSmartCameraPlaybackStatePaused,
    TuyaSmartCameraPlaybackStateFinished
};

typedef NSArray<NSNumber *> TYNumberArray;
typedef NSArray<NSDictionary *> TYDictArray;

@class TuyaSmartCameraDefault;

@protocol TuyaSmartCameraObserver <NSObject>

@optional

- (void)cameraDidConnected:(TuyaSmartCameraDefault *)camera;

- (void)cameraDidDisconnected:(TuyaSmartCameraDefault *)camera;

- (void)cameraDidStartPreview:(TuyaSmartCameraDefault *)camera;

- (void)cameraDidStopPreview:(TuyaSmartCameraDefault *)camera;

- (void)camera:(TuyaSmartCameraDefault *)camera playbackStateDidChagned:(TuyaSmartCameraPlaybackState)playbackState;

- (void)cameraDidStartTalk:(TuyaSmartCameraDefault *)camera;

- (void)cameraDidStopTalk:(TuyaSmartCameraDefault *)camera;

- (void)cameraDidStartRecording:(TuyaSmartCameraDefault *)camera;

- (void)cameraDidStopRecording:(TuyaSmartCameraDefault *)camera;

- (void)camera:(TuyaSmartCameraDefault *)camera muteStateDidChanged:(BOOL)isMuted;

- (void)camera:(TuyaSmartCameraDefault *)camera definitionStateDidChanged:(BOOL)isHD;

- (void)camera:(TuyaSmartCameraDefault *)camera didOccurredError:(TYCameraErrorCode)errCode;

@end

@interface TuyaSmartCameraDefault : NSObject

@property (nonatomic, strong, readonly) TuyaSmartDevice *device;

@property (nonatomic, strong, readonly) id<TuyaSmartCameraType> camera;

@property (nonatomic, strong, readonly) UIView<TuyaSmartVideoViewType> *videoView;

@property (nonatomic, strong, readonly) TuyaSmartCameraDPManager *dpManager;

@property (nonatomic, assign) TuyaSmartCameraPlayMode playMode;

@property (nonatomic, assign) TuyaSmartCameraTalkbackMode talkbackMode;

@property (nonatomic, assign, readonly)                 BOOL isSupportInstantTalkback;

@property (nonatomic, assign, getter=isConnecting)      BOOL connecting;

@property (nonatomic, assign, getter=isConnected)       BOOL connected;

@property (nonatomic, assign, getter=isPreviewing)      BOOL previewing;

@property (nonatomic, assign, getter=isPlaybacking)     BOOL playbacking;

@property (nonatomic, assign, getter=isPlaybackPuased)  BOOL playbackPaused;

@property (nonatomic, assign, getter=isMuted)           BOOL muted;

@property (nonatomic, assign, getter=isTalking)         BOOL talking;

@property (nonatomic, assign, getter=isRecording)       BOOL recording;

@property (nonatomic, assign, getter=isHD)              BOOL HD;

@property (nonatomic, strong, readonly) TYDictArray *timeSlicesInCurrentDay;

@property (nonatomic, strong, readonly) NSSet<id<TuyaSmartCameraObserver>> *observers;

- (instancetype)initWithDeviceId:(NSString *)devId;

- (void)addObserVer:(id<TuyaSmartCameraObserver>)observer;

- (void)removeObserver:(id<TuyaSmartCameraObserver>)observer;

- (void)connect;

- (void)disConnect;

- (void)startPreview;

- (void)stopPreview;

- (void)startPlaybackWithPlayTime:(NSInteger)playTime playbackSlice:(NSDictionary *)timeSlice;

- (void)pausePlayback;

- (void)resumePlayback;

- (void)stopPlayback;

- (void)playbackDaysInYear:(NSInteger)year month:(NSInteger)month complete:(void(^)(TYNumberArray * result))complete;

- (void)recordTimeSliceWithPlaybackDate:(TuyaSmartPlaybackDate *)date complete:(void(^)(TYDictArray *result))complete;

- (void)startTalk;

- (void)stopTalk;

- (UIImage *)snapShoot;

- (void)startRecord;

- (void)stopRecord;

@end

