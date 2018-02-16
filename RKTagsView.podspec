#
# Be sure to run `pod lib lint RKTagsView.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = "RKTagsView"
  s.version          = "1.3.4"
  s.summary          = "Highly customizable iOS tags view (like NSTokenField)."
  s.homepage         = "https://github.com/kuler90/RKTagsView"
  s.screenshots      = "https://raw.githubusercontent.com/kuler90/RKTagsView/master/sample.gif"
  s.license          = 'MIT'
  s.author           = { "Roman Kulesha" => "kulesha.r@gmail.com" }
  s.source           = { :git => "https://github.com/kuler90/RKTagsView.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Source/*'

end
