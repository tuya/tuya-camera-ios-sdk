Pod::Spec.new do |s|
  s.name = "TuyaSmartCameraKit"
  s.version = "4.3.7"
  s.summary = "open SDK code for tuya smart camera."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"fulang@tuya.com"=>"fulang@tuya.com"}
  s.homepage = "https://tuya.com"
  s.source = { :http => "https://airtake-public-data.oss-cn-hangzhou.aliyuncs.com/smart/app/package/sdk/ios/#{s.name}-#{s.version}.zip", :type => "zip" }

  s.static_framework = true

  s.frameworks = ["UIKit", "Foundation", "AVFoundation", "Foundation", "Photos"]
  s.libraries = ["c++", "z", "iconv", "bz2", "resolv"]

  s.ios.deployment_target    = '9.0'
  s.ios.vendored_framework   = 'ios/TuyaSmartCameraKit.framework'

  s.dependency 'TuyaSmartCameraBase'
  s.dependency 'TuyaSmartBaseKit'
  s.dependency 'TuyaSmartDeviceKit'
  s.dependency 'TuyaSmartCameraM'
  
end
