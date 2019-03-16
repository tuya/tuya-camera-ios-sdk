//
//  TYPermissionUtil.h
//  TuyaSmartPublic
//
//  Created by xuyongbo on 2017/11/22.
//  Copyright © 2017年 Tuya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TuyaSmartHomeKit/TuyaSmartKit.h>

@interface TYPermissionUtil : NSObject

+ (BOOL)isPhotoLibraryDenied;
+ (BOOL)isPhotoLibraryNotDetermined;
+ (void)requestPhotoPermission:(TYSuccessBOOL)result;

+ (BOOL)microNotDetermined;
+ (BOOL)microDenied;
+ (void)requestAccessForMicro:(TYSuccessBOOL)result;

+ (void)showAppSettingsTip:(NSString *)tip;

@end
