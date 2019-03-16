//
//  TuyaSmartLoginManager.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/1/2.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartLoginManager.h"
#import <TuyaSmartHomeKit/TuyaSmartKit.h>

@implementation TuyaSmartLoginManager

+ (instancetype)sharedManager {
    static TuyaSmartLoginManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [TuyaSmartLoginManager new];
    });
    return _instance;
}

+ (void)loginByUid:(NSString *)countryCode
               uid:(NSString *)uid
          password:(NSString *)password
          complete:(void(^)(NSError *error))complete {
    [[TuyaSmartUser sharedInstance] loginByUid:uid password:password countryCode:countryCode success:^{
        !complete?:complete(nil);
    } failure:complete];
}

+ (void)loginByPhone:(NSString *)countryCode
        phoneNumber:(NSString *)phoneNumber
           password:(NSString *)password
           complete:(void(^)(NSError *error))complete {
    [[TuyaSmartUser sharedInstance] loginByPhone:countryCode phoneNumber:phoneNumber password:password success:^{
        !complete?:complete(nil);
    } failure:complete];
}

+ (void)loginByEmail:(NSString *)countryCode
               email:(NSString *)email
            password:(NSString *)password
            complete:(void(^)(NSError *error))complete {
    [[TuyaSmartUser sharedInstance] loginByEmail:countryCode email:email password:password success:^{
        !complete?:complete(nil);
    } failure:complete];
}

+ (void)loginOut {
    [[TuyaSmartUser sharedInstance] loginOut:nil failure:nil];
}

@end
