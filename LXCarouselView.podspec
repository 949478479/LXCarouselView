Pod::Spec.new do |s|

s.name = "LXCarouselView"

s.version = "0.1.0"

s.summary = "利用 UICollectionView 实现的轮播图，可通过 UICollectionViewCell 自定义内容。"

s.homepage = "https://github.com/949478479/LXCarouselView"

s.license = "MIT"

s.author = { "吕小怼" => "949478479@qq.com" }

s.platform = :ios, "9.0"

s.source = { :git => "https://github.com/949478479/LXCarouselView.git", :tag => "#{s.version}" }

s.source_files = "Source/*.{swift}"

end
