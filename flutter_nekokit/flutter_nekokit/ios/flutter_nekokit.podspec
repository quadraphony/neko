#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_nekokit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_nekokit'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for integrating with NekoBoxForAndroid\'s sing-box core.'
  s.description      = <<-DESC
A Flutter plugin that provides a Dart API for integrating with NekoBoxForAndroid's sing-box core,
enabling proxy functionality for both Android and iOS platforms.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # IMPORTANT: You will need to add the sing-box core framework as a dependency here.
  # This typically involves compiling the Go sing-box library into an iOS framework
  # and adding it as a vendored framework or dependency.
  # Example:
  # s.vendored_frameworks = 'Frameworks/SingBoxCore.framework'
  # or
  # s.dependency 'SingBoxCore', '~> 1.0'
  
  # For now, this is left as a comment since the sing-box core for iOS
  # needs to be manually compiled and integrated.
end

