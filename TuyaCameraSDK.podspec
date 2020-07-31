#
# Be sure to run `pod lib lint TuyaCameraSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TuyaCameraSDK'
  s.version          = '3.17.3'
  s.summary          = 'open SDK code for tuya smart camera.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://registry.code.tuya-inc.top/tuyaIOSCamera/ipc-client-cxx-camera-sdk'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wangjing@tuya.com' => 'wangjing@tuya.com' }
  s.source = { :http => "https://airtake-public-data-1254153901.cos.ap-shanghai.myqcloud.com/smart/app/package/sdk/ios/#{s.name}-#{s.version}.zip", :type => "zip" }

  s.ios.deployment_target = '9.0'

  s.vendored_frameworks  = 'ios/*.framework'
  
  s.libraries  = 'c++', 'z', 'iconv', 'bz2', 'resolv'
  s.frameworks = 'Foundation','AVFoundation','Foundation','CoreAudio','CoreMedia','CoreVideo','VideoToolbox','MediaToolBox'

end
