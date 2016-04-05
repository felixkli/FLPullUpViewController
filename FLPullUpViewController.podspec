Pod::Spec.new do |s|

  s.name         = "FLPullUpViewController"
  s.version      = "0.0.1"
  s.summary      = "A short description of FLPullUpViewController."
  s.homepage     = "https://github.com/felixkli/FLPullUpViewController"
  s.license      = 'MIT'
  s.author       = { "Felix Li" => "li.felix162@gmail.com" }
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/felixkli/FLPullUpViewController.git", :tag => "0.0.1" }
  s.source_files = 'FLPullUpViewController.swift', 'DarkScreenView.swift'

end
