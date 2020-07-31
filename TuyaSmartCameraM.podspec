Pod::Spec.new do |s|
  s.name = "TuyaSmartCameraM"
  s.version = "4.17.3"
  s.summary = "open SDK code for tuya smart camera."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"fulang@tuya.com"=>"fulang@tuya.com"}
  s.homepage = "https://tuya.com"
  s.frameworks = ["UIKit", "Foundation", "AVFoundation", "Foundation", "CoreAudio", "CoreMedia", "CoreVideo", "VideoToolbox", "MediaToolBox", "Photos"]
  s.libraries = ["c++", "z", "iconv", "bz2", "resolv"]
  s.source = { :http => "https://airtake-public-data-1254153901.cos.ap-shanghai.myqcloud.com/smart/app/package/sdk/ios/#{s.name}-#{s.version}.zip", :type => "zip" }
  s.static_framework = true
  s.ios.deployment_target    = '9.0'
  s.ios.vendored_frameworks   = 'ios/*.framework'

  s.dependency 'TuyaCameraSDK'
  s.dependency 'TuyaSmartCameraBase'
  s.dependency 'TuyaSmartBaseKit'
  s.dependency 'TuyaSmartDeviceKit'
  
end
