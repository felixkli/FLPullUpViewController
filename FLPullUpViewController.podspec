Pod::Spec.new do |s|

  s.name         = "FLPullUpViewController"
  s.version      = "0.0.2"
  s.summary      = "A pull up controller that appears from the bottom."
  s.homepage     = "https://github.com/felixkli/FLPullUpViewController"
  s.license      = 'MIT'
  s.author       = { "Felix Li" => "li.felix162@gmail.com" }
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/felixkli/FLPullUpViewController.git", :tag => "0.0.2" }
  s.source_files = 'FLPullUpViewController.swift', 'DarkScreenView.swift'
end
