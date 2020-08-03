Pod::Spec.new do |s|

  s.name         = "FLPullUpViewController"
  s.version      = "0.5.17"
  s.summary      = "A pull up controller that appears from the bottom."
  s.homepage     = "https://github.com/felixkli/FLPullUpViewController"
  s.license      = 'MIT'
  s.author       = { "Felix Li" => "li.felix162@gmail.com" }
  s.platform     = :ios, "9.0"
  s.ios.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/felixkli/FLPullUpViewController.git", :tag => s.version.to_s }
  s.source_files = 'FLPullUpViewController.swift', 'DarkScreenView.swift'
  s.resources = 'Resources/Media.xcassets'
  s.swift_version = '5.0'
end
