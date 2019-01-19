//
//  TuyaSmartCameraDefines.h
//  TuyaSmartCamera
//
//  Created by 傅浪 on 2019/1/10.
//

#ifndef TuyaSmartCameraDefines_h
#define TuyaSmartCameraDefines_h

typedef enum
{
    TUYA_MEDIA_CODEC_UNKNOWN           = 0x00,
    TUYA_MEDIA_CODEC_VIDEO_MPEG4       = 0x4C,
    TUYA_MEDIA_CODEC_VIDEO_H263        = 0x4D,
    TUYA_MEDIA_CODEC_VIDEO_H264        = 0x4E,
    TUYA_MEDIA_CODEC_VIDEO_MJPEG       = 0x4F,
    TUYA_MEDIA_CODEC_VIDEO_H265        = 0x50,

}TUYA_ENUM_CODECID;

typedef struct {
    TUYA_ENUM_CODECID      codec_id;           // video coding mode
    unsigned long          timeStamp;          // video time stamp
} TuyaSmartVideoFrameInfo;

typedef enum {
    TY_ERROR_NONE,                      // 0
    TY_ERROR_CONNECT_FAILED,            // 1    connect failed
    TY_ERROR_CONNECT_DISCONNECT,        // 2    connect did disconnected
    TY_ERROR_ENTER_PLAYBACK_FAILED,     // 3    connect playback channel failed
    TY_ERROR_START_PREVIEW_FAILED,      // 4    preview failed. if the connection is broken during hte preview process, it will alse call back this error.
    TY_ERROR_START_PLAYBACK_FAILED,     // 5    playback failed. if the connection is broken during the playback process, it will alse call back this error.
    TY_ERROR_PAUSE_PLAYBACK_FAILED,     // 6    pause playabck failed
    TY_ERROR_RESUME_PLAYBACK_FAILED,    // 7    resume playabck failed
    TY_ERROR_ENABLE_MUTE_FAILED,        // 8    mute failed.
    TY_ERROR_START_TALK_FAILED,         // 9    start talk to device failed
    TY_ERROR_SNAPSHOOT_FAILED,          // 10   get screenshot failed
    TY_ERROR_RECORD_FAILED,             // 11   record video failed
    TY_ERROR_ENABLE_HD_FAILED,          // 12   set definition state failed
    TY_ERROR_GET_HD_FAILED,             // 13   get definition state failed
    TY_ERROR_QUERY_RECORD_DAY_FAILED,   // 14   query video record date failed
    TY_ERROR_QUERY_TIMESLICE_FAILED,    // 15   query video record slice failed
} TYCameraErrorCode;

typedef NS_ENUM(NSUInteger, TuyaSmartCameraPlayMode) {
    TuyaSmartCameraPlayModeNone,
    TuyaSmartCameraPlayModePreview,     // live
    TuyaSmartCameraPlayModePlayback     // playback
};


#endif /* TuyaSmartCameraDefines_h */
