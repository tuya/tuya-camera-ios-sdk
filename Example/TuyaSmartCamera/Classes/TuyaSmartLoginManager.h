//
//  TuyaSmartLoginManager.h
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/1/2.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TuyaSmartLoginManager : NSObject

+ (instancetype)sharedManager;

+ (void)loginByPhone:(NSString *)countryCode
         phoneNumber:(NSString *)phoneNumber
            password:(NSString *)password
            complete:(void(^)(NSError *error))complete;

+ (void)loginByEmail:(NSString *)countryCode
               email:(NSString *)email
            password:(NSString *)password
            complete:(void(^)(NSError *error))complete;

+ (void)loginByUid:(NSString *)countryCode
               uid:(NSString *)uid
          password:(NSString *)password
          complete:(void(^)(NSError *error))complete;

+ (void)loginOut;

@end

NS_ASSUME_NONNULL_END
