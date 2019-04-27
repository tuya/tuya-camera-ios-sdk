#
# Be sure to run `pod lib lint TuyaSmartCamera.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TuyaSmartCamera'
  s.version          = '3.1.2'
  s.summary          = '涂鸦智能摄像头iOS SDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
涂鸦智能摄像头APP SDK提供了与摄像头通讯的接口封装，快速实现摄像头实时视频传输，录制视频回放等功能.
                       DESC

  s.homepage         = 'https://github.com/TuyaInc/tuyasmart_camera_ios_sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'fulang@tuya.com' => 'fulang@tuya.com' }
  s.source           = { :http => "https://airtake-public-data.oss-cn-hangzhou.aliyuncs.com/smart/app/package/sdk/ios/#{s.name}-#{s.version}.zip", :type => "zip" }

  s.ios.deployment_target = '8.0'
  
  s.libraries  = 'c++', 'z', 'iconv', 'bz2', 'resolv'
  s.frameworks = 'UIKit','Foundation','AVFoundation','Foundation','CoreAudio','CoreMedia','CoreVideo','MediaToolBox','VideoToolbox','Photos'
  
  s.default_subspec = 'Tuya'

  s.subspec 'Tuya' do |tuya|
    tuya.source_files = 'TuyaSmartCamera/Classes/*.{h,m}'
    tuya.vendored_frameworks = 'TuyaSmartCamera/Venders/M/*.framework'
    tuya.dependency 'TuyaSmartHomeKit'
  end

  s.subspec 'ALL' do |all|
    all.vendored_frameworks = 'TuyaSmartCamera/Venders/T/*.framework'
    all.dependency 'TuyaSmartCamera/Tuya'
  end
end
