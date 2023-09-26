Pod::Spec.new do |s|
  s.name         = "Refreshing"
  s.version      = "1.1.0"
  s.summary      = "An easy way to implement pull-to-refresh feature based on UIScrollView extension."
  s.homepage     = "https://github.com/iLiuChang/Refreshing"
  s.license      = "MIT"
  s.authors      = { "iLiuChang" => "iliuchang@foxmail.com" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/iLiuChang/Refreshing.git", :tag => s.version }
  s.requires_arc = true
  s.swift_version = "5.0"
  s.source_files = "Source/*.{swift}"
end
