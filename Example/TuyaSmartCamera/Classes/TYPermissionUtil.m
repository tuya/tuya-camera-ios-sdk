//
//  TYPermissionUtil.m
//  TuyaSmartPublic
//
//  Created by xuyongbo on 2017/11/22.
//  Copyright © 2017年 Tuya. All rights reserved.
//

#import "TYPermissionUtil.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@implementation TYPermissionUtil

#pragma mark - Photo Permission

+ (BOOL)isPhotoLibraryDenied {
    if(PHAuthorizationStatusRestricted == [PHPhotoLibrary authorizationStatus] || PHAuthorizationStatusDenied == [PHPhotoLibrary authorizationStatus]){
        return YES;
    }
    return NO;
}

+ (BOOL)isPhotoLibraryNotDetermined {
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined)
        return YES;
    return NO;
}

+ (void)requestPhotoPermission:(TYSuccessBOOL)result {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if(PHAuthorizationStatusAuthorized == status){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result) result(YES);
            });
        }
    }];
}

#pragma mark - Micro Permission

//麦克风未授权
+ (BOOL)microNotDetermined {
    NSString *mediaType = AVMediaTypeAudio;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusNotDetermined) {
        return YES;
    }
    return NO;
}

//麦克风权限拒绝
+ (BOOL)microDenied {
    __block BOOL microDenied = NO;
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            //无麦克风权限
            microDenied = YES;
        } else {
            microDenied = NO;
        }
    }];
    return microDenied;
}

//请求麦克风权限
+ (void)requestAccessForMicro:(TYSuccessBOOL)result {
    NSString *mediaType = AVMediaTypeAudio;
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) result(granted);
        });
    }];
}

+ (void)showAppSettingsTip:(NSString *)tip {
//    [UIAlertView bk_showAlertViewWithTitle:nil message:tip cancelButtonTitle:NSLocalizedString(@"action_cancel", nil) otherButtonTitles:@[NSLocalizedString(@"open_permisions", nil)] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
//        if (buttonIndex == 1) {
//            if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
//                [[UIApplication sharedApplication] openURL: [NSURL URLWithString:UIApplicationOpenSettingsURLString]];
//            }
//        }
//    }];
}

@end
