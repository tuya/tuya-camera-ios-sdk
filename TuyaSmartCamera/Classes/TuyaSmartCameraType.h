//
//  TuyaSmartCameraType.h
//  TYCameraLibrary
//
//  Created by Tuya on 2018/7/2.
//  Copyright © 2018 TuyaSmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuyaSmartCameraDefines.h"
#import "TuyaSmartVideoViewType.h"
#import <CoreMedia/CoreMedia.h>

IPC_EXTERN NSString * const kTuyaSmartTimeSliceStartDate;

IPC_EXTERN NSString * const kTuyaSmartTimeSliceStopDate;

IPC_EXTERN NSString * const kTuyaSmartTimeSliceStartTime;

IPC_EXTERN NSString * const kTuyaSmartTimeSliceStopTime;

@protocol TuyaSmartCameraType;

@protocol TuyaSmartCameraDelegate <NSObject>

@optional

/**
 the p2p channel did connected.

 @param camera camera
 */
- (void)cameraDidConnected:(id<TuyaSmartCameraType>)camera;

/**
 the p2p channel did disconnected.

 @param camera camera
 */
- (void)cameraDisconnected:(id<TuyaSmartCameraType>)camera;

/**
 the playback channel did connected.

 @param camera camera
 */
- (void)cameraDidConnectPlaybackChannel:(id<TuyaSmartCameraType>)camera;

/**
 the camera did began play live video.

 @param camera camera
 */
- (void)cameraDidBeginPreview:(id<TuyaSmartCameraType>)camera;

/**
 the camera did stop live video.

 @param camera camera
 */
- (void)cameraDidStopPreview:(id<TuyaSmartCameraType>)camera;

/**
 the camera did began playback record video in the SD card.

 @param camera camera
 */
- (void)cameraDidBeginPlayback:(id<TuyaSmartCameraType>)camera;

/**
 the camera did pause playback record video in the SD card.

 @param camera camera
 */
- (void)cameraDidPausePlayback:(id<TuyaSmartCameraType>)camera;

/**
 the camera did resume playback record video in the SD card.

 @param camera camera
 */
- (void)cameraDidResumePlayback:(id<TuyaSmartCameraType>)camera;

/**
 the camera did stop playback record video in the SD card.

 @param camera camera
 */
- (void)cameraDidStopPlayback:(id<TuyaSmartCameraType>)camera;

/**
 the record video in the SD card playback finished.

 @param camera camera
 */
- (void)cameraPlaybackDidFinished:(id<TuyaSmartCameraType>)camera;

/**
 receive first video frame
 this method will call when every 'startPreview/startPlayback/resumePlayback' sucess.
 @param camera camera
 */
- (void)cameraDidReceiveFirstFrame:(id<TuyaSmartCameraType>)camera;

/**
 could talk to the device. will call when 'startTalk' success.

 @param camera camera
 */
- (void)cameraDidBeginTalk:(id<TuyaSmartCameraType>)camera;

/**
 talk to the device did stop. will call when 'stopTalk' success.

 @param camera camera
 */
- (void)cameraDidStopTalk:(id<TuyaSmartCameraType>)camera;

/**
 the video screenshot has saved in the photo album.

 @param camera camera
 */
- (void)cameraSnapShootSuccess:(id<TuyaSmartCameraType>)camera;

/**
 video recording did start success.

 @param camera camera
 */
- (void)cameraDidStartRecord:(id<TuyaSmartCameraType>)camera;

/**
 video recording did stop sucess, and the video has saved in photo album success.

 @param camera camera
 */
- (void)cameraDidStopRecord:(id<TuyaSmartCameraType>)camera;

/**
 did receive definition state. will call when 'getHD' success or the definition has changed.

 @param camera camera
 @param isHd is high definition
 */
- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveDefinitionState:(BOOL)isHd;

/**
 called when query date of the playback record success.

 @param camera camera
 @param days the array of days，ex: [@(1), @(2), @(5), @(6), @(31)]; express in this month, 1，2，5，6，31  has video record.
 */
- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveRecordDayQueryData:(NSArray<NSNumber *> *)days;

/**
 called when query video record slice of one day success.

 @param camera camera
 
 @param timeSlices the array of playback video record information. the element is a NSDictionary, content like this:
 kTuyaSmartPlaybackPeriodStartDate  ： startTime(NSDate)
 kTuyaSmartPlaybackPeriodStopDate   ： stopTime(NSDate)
 kTuyaSmartPlaybackPeriodStartTime  ： startTime(NSNumer, unix timestamp)
 kTuyaSmartPlaybackPeriodStopTime   ： stopTime(NSNumer, unix timestamp)
 */
- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveTimeSliceQueryData:(NSArray<NSDictionary *> *)timeSlices;

/**
 did receive mute state. will call when 'enableMute:' success. default is YES.

 @param camera camera
 @param isMute is muted
 */
- (void)camera:(id<TuyaSmartCameraType>)camera didReceiveMuteState:(BOOL)isMute playMode:(TuyaSmartCameraPlayMode)playMode;

/**
 the control of camera has occurred an error
 @param camera camera
 @param errCode reference the TYCameraErrorCode
 */
- (void)camera:(id<TuyaSmartCameraType>)camera didOccurredError:(TYCameraErrorCode)errCode;

/**
 the definition of the video did chagned
 @param camera camera
 @param width video width
 @param height video height
 */
- (void)camera:(id<TuyaSmartCameraType>)camera resolutionDidChangeWidth:(NSInteger)width height:(NSInteger)height;

/**
 if 'isRecvFrame' is true, and p2pType is "1", the video data will not decode in the SDK, and could get the orginal video frame data through this method.
 @param camera      camera
 @param frameData   original video frame data
 @param size        video frame data size
 @param frameInfo   frame header info
 */

- (void)camera:(id<TuyaSmartCameraType>)camera ty_didReceiveFrameData:(const char *)frameData dataSize:(unsigned int)size frameInfo:(TuyaSmartVideoStreamInfo)frameInfo;

/**
 if 'isRecvFrame' is true, and p2pType is "2", could get the decoded YUV frame data through this method.
 @param camera          camera
 @param sampleBuffer    video frame YUV data
 @param frameInfo       frame header info
 */
- (void)camera:(id<TuyaSmartCameraType>)camera ty_didReceiveVideoFrame:(CMSampleBufferRef)sampleBuffer frameInfo:(TuyaSmartVideoFrameInfo)frameInfo;

@end

@protocol TuyaSmartCameraType <NSObject>

@property (nonatomic, weak) id<TuyaSmartCameraDelegate> delegate;

/// if you want get the original video frame data, set isRecvFrame YES.
@property (nonatomic, assign) BOOL isRecvFrame;

/**
 destory resources, should call this method when exit the camera panel.
 */
- (void)destory;

/**
 start connect p2p channel
 */
- (void)connect;

/**
 connnect playback channel, call this method before start playback video record.
 */
- (void)enterPlayback;

/**
 disconnect p2p channel
 */
- (void)disConnect;

/**
 get current video width
 
 @return video width
 */
- (CGFloat)getCurViewWidth;

/**
 get current video height
 
 @return video height
 */
- (CGFloat)getCurViewHeight;

/**
 start live video
 */
- (void)startPreview;

/**
 stop live video
 */
- (void)stopPreview;

/**
 video frame render view
 
 @return render view
 */
- (UIView<TuyaSmartVideoViewType> *)videoView;

/**
 enable mute state, the default is YES
 
 @param mute is mute
 */
- (void)enableMute:(BOOL)mute forPlayMode:(TuyaSmartCameraPlayMode)playMode;

/**
 start talk to device
 */
- (void)startTalk;

/**
 stop talk to device.
 */
- (void)stopTalk;

/**
 start record video, the video record will saved in photo album.
 */
- (void)startRecord;

/**
 stop record video.
 */
- (void)stopRecord;

/**
 get a screenshot of th video and save it to photo album. photo asset collection name is bundle name, "[NSBundle mainBundle].infoDictionary[(__bridge NSString *)kCFBundleNameKey]".
 */
- (UIImage *)snapShoot;

/**
 enbale high definition
 
 @param hd is high definition
 */
- (void)enableHD:(BOOL)hd;

/**
 get the definition state
 */
- (void)getHD;

/**
 query the date of video recording in a month.

 @param year ex: 2019
 @param month ex: 1
 */
- (void)queryRecordDaysWithYear:(NSUInteger)year month:(NSUInteger)month;

/**
 query all video record slices for a particular day.
 
 @param year ex: 2019
 @param month ex: 1
 @param day ex: 3
 */
- (void)queryRecordTimeSliceWithYear:(NSUInteger)year month:(NSUInteger)month day:(NSUInteger)day;

/**
 start playback from a point in time, using unix timestamp
 
 @param playTime play time
 @param startTime start time of a video slice
 @param stopTime end time of a video slice
 */
- (void)startPlayback:(NSInteger)playTime startTime:(NSInteger)startTime stopTime:(NSInteger)stopTime;

/**
 pause playback
 */
- (void)pausePlayback;

/**
 resume play back
 */
- (void)resumePlayback;

/**
 stop play back
 */
- (void)stopPlayback;

@end
