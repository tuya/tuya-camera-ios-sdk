Pod::Spec.new do |s|
  s.name = "TuyaSmartCameraBase"
  s.version = "4.17.0"
  s.summary = "open SDK code for tuya smart camera."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"Tuya SDK"=>"developer@tuya.com"}
  s.homepage = "https://tuya.com"
  s.source = { :http => "https://airtake-public-data-1254153901.cos.ap-shanghai.myqcloud.com/smart/app/package/sdk/ios/#{s.name}-#{s.version}.zip", :type => "zip" }

  s.static_framework = true

  s.ios.frameworks = 'Foundation','AVFoundation','Photos'
  s.ios.deployment_target    = '9.0'
  s.ios.vendored_framework   = 'ios/TuyaSmartCameraBase.framework'
end
