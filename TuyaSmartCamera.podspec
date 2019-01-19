#
# Be sure to run `pod lib lint TuyaSmartCamera.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TuyaSmartCamera'
  s.version          = '3.1.0'
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
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'fulang@tuya.com' => 'fulang@tuya.com' }
  s.source           = { :git => 'https://github.com/TuyaInc/tuyasmart_camera_ios_sdk.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  
  # s.resource_bundles = {
  #   'TuyaSmartCamera' => ['TuyaSmartCamera/Assets/*.png']
  # }

  s.vendored_frameworks = 'TuyaSmartCamera.framework'
  s.preserve_paths      = 'TuyaSmartCamera.framework'

  s.libraries  = 'c++', 'z', 'iconv', 'bz2', 'resolv'
  s.frameworks = 'UIKit','Foundation','AVFoundation','Foundation','CoreAudio','CoreMedia','CoreVideo','MediaToolBox','Photos'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
