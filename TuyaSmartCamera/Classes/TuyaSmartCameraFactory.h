//
//  TuyaSmartCameraFactory.h
//  TYCameraLibrary
//
//  Created by 傅浪 on 2018/7/6.
//  Copyright © 2018 TuyaSmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuyaSmartCameraType.h"

@interface TuyaSmartCameraConfig : NSObject

/**
 Get the configuration data through the "tuya.m.ipc.config.get" api, the value of the "p2pId" field in the data.
 */
@property (nonatomic, strong) NSString *p2pId;

/**
 Get the configuration data through the "tuya.m.ipc.config.get" api, the value of the "password" field in the data.
 */
@property (nonatomic, strong) NSString *password;

/**
 Get the configuration data through the "tuya.m.ipc.config.get" api, the value of the "p2pConfig" field in the data.if there is no "p2pConfig" field, set nil.
 */
@property (nonatomic, strong) NSDictionary *p2pConfig;

/**
 The "localKey" property in the TuyaSmartDeviceModel object corresponding to the camera device.
 
 */
@property (nonatomic, strong) NSString *localKey;

@end

@interface TuyaSmartCameraFactory : NSObject

+ (void)initSDKs __deprecated_msg("SDK will auto init when create camera instance");

/**
 get the camera sdk version
 */
+ (NSString *)tuyaSmartCameraVersion;

/**
 create a camera instance

 @param type p2p type，pass the value of the "p2pType" field in the "skills" attribute of the "TuyaSmartDeviceModel" object corresponding to the camera device.
 
 @param ipcConfig camera config
 @param delegate delgate
 @return camera instance
 */
+ (id<TuyaSmartCameraType>)cameraWithP2PType:(id)type config:(TuyaSmartCameraConfig *)ipcConfig delegate:(id<TuyaSmartCameraDelegate>)delegate;

@end
