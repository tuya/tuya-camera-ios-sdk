#### Note: This repository is inherited from the [old Tuya Github repository](https://github.com/TuyaInc/tuyasmart_camera_ios_sdk), which will be deprecated soon. Use this repository for Tuya SDK development instead. You can change the existing remote repository URL. For more information, see [Tutorial](https://docs.github.com/en/free-pro-team@latest/github/using-git/changing-a-remotes-url).

# Tuya Smart Camera iOS SDK

[English](./README.md) | [中文版](./README-zh.md)

---

## Overview

Tuya Smart Camera SDK provides the interface package for communication with remote camera devices to accelerate the application development process. The following features are supported:

* Preview pictures that are taken by cameras
* Play back recorded video of cameras
* Record video
* Talk to remote cameras

## Efficient integration

#### Use CocoaPods integration（version 8.0 or later is supported）

Add the following content to the file 'Podfile':

```ruby
platform :ios, '9.0'

target 'your_target_name' do

  pod "TuyaSmartActivatorKit"
	pod 'TuyaSmartCameraKit'
  pod 'TYEncryptImage'
	#pod 'TuyaSmartCameraT'

end
```

By default, TuyaSmartCameraKit does not support P2P 1.0. To integrate P2P 1.0 cameras, add this code: `pod 'TuyaSmartCameraT'`.

`TuyaSmartCamera` is removed from the SDK. You can get it from the demo in this repo.

Execute the command ```pod update``` in the project's root directory to begin integration.

For more information about CocoaPods, see [CocoaPods Guides](https://guides.cocoapods.org/).

## References

For more information, see [Tuya Smart Camera iOS SDK](https://developer.tuya.com/en/docs/app-development/ios-app-sdk/extension-sdk/ipc-sdk/ipccamera?id=Ka5vexydbwua5).

## Demo

1. Clone this repo to local.

2. Open your terminal and run the following command:

   ```ruby
   cd tuyasmart_camera_ios_sdk/Example/
   pod install
   ```

3. Open `TuyaSmartHomeKit.xcworkspace`.

4. Add the security image to the project and modify the value of `bundleId`. For more information, see [Preparation](https://developer.tuya.com/en/docs/app-development/preparation/preparation?id=Ka69nt983bhh5).

5. Open the file `TYAppDelegate.m` and set `appKey` and `appSecret`. If you require `TYCameraCloudServicePanelSDK`, set the channel ID of the app.

6. Run the project. Hardware decoding is used in the SDK. We recommend that you debug with iPhone.

## Changelog

[Changelog](https://developer.tuya.com/en/docs/app-development/ios-app-sdk/extension-sdk/ipc-sdk/versionrecord?id=Ka5vox6pd09cn)

## Support

You can get support from Tuya Smart by using the following methods:

* Tuya Smart Help Center: https://support.tuya.com/en/help

* Technical Support Console: https://service.console.tuya.com/

## License

This Tuya Home iOS SDK Sample is licensed under the MIT License.
