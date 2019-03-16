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
platform :ios, '8.0'

target 'your_target_name' do

   pod 'TuyaSmartCamera'
   pod 'TuyaSmartHomeKit'

end

```

然后在项目根目录下执行`pod update`命令，集成第三方库。

CocoaPods的使用请参考：[CocoaPods Guides](https://guides.cocoapods.org/)

## 开发文档

更多请参考：[涂鸦智能摄像头 iOS SDK使用说明](https://tuyainc.github.io/tuyasmart_camera_ios_sdk_doc/zh-hans/)
