//
//  TuyaSmartCameraControlView.h
//  TuyaSmartCamera_Example
//
//  Copyright (c) 2014-2021 Tuya Inc. (https://developer.tuya.com/)

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

