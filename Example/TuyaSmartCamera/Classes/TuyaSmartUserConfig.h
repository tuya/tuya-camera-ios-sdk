//
//  TuyaSmartUserConfig.h
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/1/10.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TuyaSmartUserConfig : NSObject

+ (NSString *)tyAppKey;

+ (NSString *)tyAppSecret;

+ (NSString *)countryCode;

+ (NSString *)phoneNumber;

+ (NSString *)email;

+ (NSString *)uid;

+ (NSString *)password;

@end

NS_ASSUME_NONNULL_END
