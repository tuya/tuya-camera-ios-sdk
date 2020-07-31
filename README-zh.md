# 涂鸦智能摄像头 iOS SDK

[中文版](./README-zh.md) | [English](./README.md)

---

## 功能概述

涂鸦智能摄像头 SDK 提供了与远端摄像头设备通讯的接口封装，加速应用开发过程，主要包括了以下功能：

- 预览摄像头实时采集的图像。
- 播放摄像头SD卡中录制的视频。
- 手机端录制摄像头采集的图像。
- 与摄像头设备通话。

## 快速集成

### 使用Cocoapods集成

在`Podfile`文件中添加以下内容：

```ruby
platform :ios, '9.0'

target 'your_target_name' do
  
	pod 'TuyaSmartActivatorKit'
	pod 'TuyaSmartCameraKit'
  pod 'TYEncryptImage'
  #pod 'TuyaSmartCameraT'

end

```

TuyaSmartCameraKit 默认不支持 p2p 1.0 的设备, 如果你需要集成 p2p 1.0 的 SDK，可以添加`pod 'TuyaSmartCameraT'`。

Demo 中有个 `TuyaSmartCamera`类，是对 TuyaCamera 功能的二次封装，集成时，可参考此类实现。

然后在项目根目录下执行`pod update`命令，集成第三方库。

CocoaPods的使用请参考：[CocoaPods Guides](https://guides.cocoapods.org/)

## 开发文档

更多请参考：[涂鸦智能摄像头 iOS SDK使用说明](https://tuyainc.github.io/tuyasmart_home_ios_sdk_doc/zh-hans/resource/Camera.html)

## Demo

1. 克隆本仓库到本地。

2. 打开终端，执行下面的命令。

   ```ruby
   cd tuyasmart_camera_ios_sdk/Example/
   pod install
   ```

3. 打开`TuyaSmartHomeKit.xcworkspace`。

4. 参考[准备工作](https://tuyainc.github.io/tuyasmart_home_ios_sdk_doc/zh-hans/resource/Preparation.html)，为项目添加加密图片，修改`bundleId`。

5. 在`TYAppDelegate.m`文件中，补充涂鸦平台上获取到的 `appKey`， `appSecret`。如果需要集成云存储服务购买的模块，还需要补充 App 的渠道标识符。

6. 运行程序。由于 SDK 采用硬件解码，建议使用真机测试。

## 版本更新记录

[版本更新记录](https://tuyainc.github.io/tuyasmart_home_ios_sdk_doc/zh-hans/resource/ipc/version_record.html)