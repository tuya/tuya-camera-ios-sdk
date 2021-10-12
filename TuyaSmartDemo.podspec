
Pod::Spec.new do |s|
  s.name             = 'TuyaSmartDemo'
  s.version          = '0.8.2'
  s.summary          = 'A short description of TuyaSmartDemo.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://registry.code.tuya-inc.top/tuyaIOSSDK/TYSDKDemo.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tuya SDK' => 'developer@tuya.com' }
  s.source           = { :git => 'https://registry.code.tuya-inc.top/tuyaIOSSDK/TYSDKDemo.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '8.0'
  
  s.default_subspec = 'UserInfo'
  
  s.subspec 'Base' do |ss|
    ss.source_files = 'TuyaSmartDemo/Classes/Base/**/*.{h,m}', 'TuyaSmartDemo/Classes/Manager/**/*.{h,m}'
    ss.resources = 'TuyaSmartDemo/Classes/Base/Assets/**/*'
    
#    ss.resource_bundles = {
#      'base' => 'TuyaSmartDemo/Classes/Base/Assets/*.{lproj,json}'
#    }
#    
    ss.prefix_header_contents = '#ifdef __OBJC__',
    '#import "TYDemoTheme.h"',
    '#import "TPDemoViewConstants.h"',
    '#import "UIView+TPDemoAdditions.h"',
    '#endif'
    
    ss.dependency 'MBProgressHUD', '~> 0.9.2'
#    ss.dependency 'BlocksKit'
    ss.dependency 'Reachability'
    ss.dependency 'YYModel'
    
    ss.dependency 'TuyaSmartBaseKit'
  end
  
  s.subspec 'Login' do |ss|
    ss.source_files = 'TuyaSmartDemo/Classes/Login/**/*.{h,m}'
    ss.dependency 'TuyaSmartDemo/Base'
    
    ss.dependency 'TuyaSmartBaseKit'
  end
  
  s.subspec 'SmartScene' do |ss|
    ss.source_files = 'TuyaSmartDemo/Classes/SmartScene/**/*.{h,m}'
    ss.resources = 'TuyaSmartDemo/Classes/SmartScene/Assets/**/*'
    
    ss.dependency 'TuyaSmartDemo/Base'
    
    ss.dependency 'SDWebImage'
    ss.dependency 'TuyaSmartSceneKit'
  end
  
  s.subspec 'DeviceList' do |ss|
    ss.source_files = 'TuyaSmartDemo/Classes/DeviceList/**/*.{h,m}'
    ss.resources = 'TuyaSmartDemo/Classes/DeviceList/Assets/**/*'
    
    ss.dependency 'TuyaSmartDemo/Base'
    
    ss.dependency 'SDWebImage'
    ss.dependency 'TuyaSmartDeviceKit'
  end
  
  s.subspec 'AddDevice' do |ss|
    ss.source_files = 'TuyaSmartDemo/Classes/AddDevice/**/*.{h,m}'
    ss.dependency 'TuyaSmartDemo/Base'
    
    ss.dependency 'SDWebImage'
    ss.dependency 'Masonry'
    ss.dependency 'TuyaSmartActivatorKit'
  end
  
  s.subspec 'UserInfo' do |ss|
    ss.source_files = 'TuyaSmartDemo/Classes/UserInfo/**/*.{h,m}'
    ss.dependency 'TuyaSmartDemo/Base'
  end
  
  s.subspec 'IPC' do |ss|
    ss.source_files = 'TuyaSmartDemo/Classes/IPC/**/*.{h,m}'
    ss.resources = 'TuyaSmartDemo/Classes/IPC/Assets/**/*'
    
    ss.dependency 'TuyaSmartDemo/Base'
    ss.dependency 'TuyaSmartCameraKit'
    ss.dependency 'TYEncryptImage'
    ss.dependency 'DACircularProgress'
  end
  
  # s.resource_bundles = {
  #   'TuyaSmartDemo' => ['TuyaSmartDemo/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
