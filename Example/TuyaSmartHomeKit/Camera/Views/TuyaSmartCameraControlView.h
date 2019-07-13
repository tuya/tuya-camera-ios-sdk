//
//  TuyaSmartCameraControlView.h
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/13.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TuyaSmartCameraControlView;

@protocol TuyaSmartCameraControlViewDelegate <NSObject>

- (void)controlView:(TuyaSmartCameraControlView *)controlView didSelectedControl:(NSString *)identifier;

@end

@interface TuyaSmartCameraControlView : UIView

@property (nonatomic, strong) NSArray *sourceData;

@property (nonatomic, weak) id<TuyaSmartCameraControlViewDelegate> delegate;

- (void)enableControl:(NSString *)identifier;

- (void)disableControl:(NSString *)identifier;

- (void)selectedControl:(NSString *)identifier;

- (void)deselectedControl:(NSString *)identifier;

- (void)enableAllControl;

- (void)disableAllControl;

@end

