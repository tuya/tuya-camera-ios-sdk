//
//  TuyaSmartCameraDPManager.h
//  TuyaSmartCamera
//
//  Created by 傅浪 on 2019/3/8.
//

#import <Foundation/Foundation.h>
#import <TuyaSmartHomeKit/TuyaSmartKit.h>
#import "TuyaSmartCameraDefines.h"

typedef NSString * TuyaSmartCameraDPKey NS_EXTENSIBLE_STRING_ENUM;
typedef NSString * TuyaSmartCameraNightvision NS_EXTENSIBLE_STRING_ENUM;
typedef NSString * TuyaSmartCaemraPIR NS_EXTENSIBLE_STRING_ENUM;
typedef NSString * TuyaSmartCameraMotion NS_EXTENSIBLE_STRING_ENUM;
typedef NSString * TuyaSmartCameraDecibel NS_EXTENSIBLE_STRING_ENUM;
typedef NSString * TuyaSmartCameraRecordMode NS_EXTENSIBLE_STRING_ENUM;
typedef NSString * TuyaSmartCameraPTZDirection NS_EXTENSIBLE_STRING_ENUM;
typedef NSString * TuyaSmartCameraPowerMode NS_EXTENSIBLE_STRING_ENUM;

/// basic setting dp
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraBasicIndicatorDPName;      // indicator light switch, Value is BOOL
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraBasicFlipDPName;           // video flip vertical switch, Value is BOOL
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraBasicOSDDPName;            // time watermark switch, Value is BOOL
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraBasicPrivateDPName;        // private mode switch, Value is BOOL
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraBasicNightvisionDPName;    // nightvision state, Value is TuyaSmartCaemraNightvision
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraBasicPIRDPName;            // PIR sensitivity

/// motion detecting alarm
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraMotionDetectDPName;        // motion detecting switch, Value is BOOL
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraMotionSensitivityDPName;   // motion detecting sensitivity state, value is TuyaSmartCameraMotion

/// decibel detecting alarm
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraDecibelDetectDPName;       // decibel detecting switch, value is BOOL
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraDecibelSensitivityDPName;  // decibel detecting sensitivity, value is TuyaSmartCameraDecibel

/// SD card
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraSDCardStatusDPName;        // sd card status, value is TuyaSmartCameraSDCardStatus, just for read
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraSDCardStorageDPName;       // sd card capacity state, Value is String, just for read
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraSDCardFormatDPName;        // sd card format command, Value is YES, just for publish
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraSDCardFormatStateDPName;   // sd card format state, Value is long : 0 - 100. if negative，is error
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraSDCardRecordDPName;        // sd card record switch, value is BOOL
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraRecordModeDPName;          // sd card record mode, value is TuyaSmartCameraRecordMode

/// ptz
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraPTZControlDPName;          // start ptz, value is TuyaSmartCameraPTZDirection, just for publish
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraPTZStopDPName;             // stop ptz, value is BOOL, just for publish

/// wireless
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraWirelessElectricityDPName; // device electricity, value is long 0 - 100, just for read
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraWirelessPowerModeDPName;   // power supply mode, value is TuyaSmartCameraPowerMode
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraWirelessLowpowerDPName;    // lowpower alarm threshold, value is long 0 - 100, just for publish. if the electricity is lower than this value, app will receive a push notification
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraWirelessBatteryLockDPName; // battery lock switch, value is BOOL
IPC_EXTERN TuyaSmartCameraDPKey const TuyaSmartCameraWirelessAwakeDPName;       // awake state, value is BOOL

/// nightvision state values
IPC_EXTERN TuyaSmartCameraNightvision const TuyaSmartCameraNightvisionAuto;
IPC_EXTERN TuyaSmartCameraNightvision const TuyaSmartCameraNightvisionOff;
IPC_EXTERN TuyaSmartCameraNightvision const TuyaSmartCameraNightvisionOn;

/// PIR state values
IPC_EXTERN TuyaSmartCaemraPIR const TuyaSmartCameraPIRStateOff;
IPC_EXTERN TuyaSmartCaemraPIR const TuyaSmartCameraPIRStateLow;
IPC_EXTERN TuyaSmartCaemraPIR const TuyaSmartCameraPIRStateMedium;
IPC_EXTERN TuyaSmartCaemraPIR const TuyaSmartCameraPIRStateHigh;

/// motion detecting sensitivity values
IPC_EXTERN TuyaSmartCameraMotion const TuyaSmartCameraMotionLow;
IPC_EXTERN TuyaSmartCameraMotion const TuyaSmartCameraMotionMedium;
IPC_EXTERN TuyaSmartCameraMotion const TuyaSmartCameraMotionHigh;

/// decibel detecting sensitivity values
IPC_EXTERN TuyaSmartCameraDecibel const TuyaSmartCameraDecibelLow;
IPC_EXTERN TuyaSmartCameraDecibel const TuyaSmartCameraDecibelHigh;

/// sd card record mode values
IPC_EXTERN TuyaSmartCameraRecordMode const TuyaSmartCameraRecordModeEvent;
IPC_EXTERN TuyaSmartCameraRecordMode const TuyaSmartCameraRecordModeAlways;

/// ptz direction values
IPC_EXTERN TuyaSmartCameraPTZDirection const TuyaSmartCameraPTZDirectionUp;
IPC_EXTERN TuyaSmartCameraPTZDirection const TuyaSmartCameraPTZDirectionRight;
IPC_EXTERN TuyaSmartCameraPTZDirection const TuyaSmartCameraPTZDirectionDown;
IPC_EXTERN TuyaSmartCameraPTZDirection const TuyaSmartCameraPTZDirectionLeft;

/// Wireless device power mode values
IPC_EXTERN TuyaSmartCameraPowerMode const TuyaSmartCameraPowerModeBattery;
IPC_EXTERN TuyaSmartCameraPowerMode const TuyaSmartCameraPowerModePlug;

/// sd card state
typedef NS_ENUM(NSUInteger, TuyaSmartCameraSDCardStatus) {
    TuyaSmartCameraSDCardStatusNormal = 1,
    TuyaSmartCameraSDCardStatusException = 2,
    TuyaSmartCameraSDCardStatusMemoryLow = 3,
    TuyaSmartCameraSDCardStatusFormatting = 4,
    TuyaSmartCameraSDCardStatusNone = 5             // not detected sd card
};

@class TuyaSmartCameraDPManager;

@protocol TuyaSmartCameraDPObserver <NSObject>

@optional

- (void)cameraDPDidUpdate:(TuyaSmartCameraDPManager *)manager dps:(NSDictionary *)dpsData;

@end

@interface TuyaSmartCameraDPManager : NSObject

- (instancetype)initWithDevice:(TuyaSmartDevice *)device;

- (instancetype)initWithDeviceId:(NSString *)devId;

- (void)addObserver:(id<TuyaSmartCameraDPObserver>)observer;

- (void)removeObserver:(id<TuyaSmartCameraDPObserver>)observer;

- (BOOL)isSurpportDP:(NSString *)dpName;

- (void)valueForDP:(NSString *)dpName success:(TYSuccessID)success failure:(TYFailureError)failure;

- (void)setValue:(id)value forDP:(NSString *)dpName success:(TYSuccessID)success failure:(TYFailureError)failure;

@end

