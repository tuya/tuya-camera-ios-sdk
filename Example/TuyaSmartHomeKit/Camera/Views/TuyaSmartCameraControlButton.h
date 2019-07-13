//
//  TuyaSmartCameraControlView.h
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/13.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TuyaSmartCameraControlButton : UIView

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, assign) BOOL highLighted;

@property (nonatomic, assign) BOOL disabled;

- (void)addTarget:(id)target action:(SEL)action;

@end
