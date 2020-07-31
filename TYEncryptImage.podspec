Pod::Spec.new do |s|
  s.name = "TYEncryptImage"
  s.version = "3.20.0"
  s.summary = "A short description of TYEncryptImage."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"fulang@tuya.com"=>"fulang@tuya.com"}
  s.homepage = "https://tuya.com"
  
  s.source = { :http => "https://airtake-public-data-1254153901.cos.ap-shanghai.myqcloud.com/smart/app/package/sdk/ios/#{s.name}-#{s.version}.zip", :type => "zip" }

  s.static_framework = true

  s.frameworks = ["UIKit", "CoreFoundation", "QuartzCore", "AssetsLibrary", "ImageIO", "Accelerate", "MobileCoreServices"]
  s.libraries = ["sqlite3", "z", "sqlite3.0"]

  s.ios.deployment_target    = '9.0'
  s.ios.vendored_framework   = 'ios/TYEncryptImage.framework'
end
