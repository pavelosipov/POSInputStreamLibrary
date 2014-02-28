Pod::Spec.new do |s|
  s.name     = 'POSInputStreamLibrary'
  s.version  = '1.0.0'
  s.license  = 'MIT'
  s.summary  = 'NSInputStream implementation for ALAsset and other kinds of data source.'
  s.homepage = 'https://github.com/pavelosipov/POSInputStreamLibrary'
  s.author   = {'Pavel Osipov => 'https://twitter.com/posipov'}
  s.source   = { :git => 'https://github.com/pavelosipov/POSInputStreamLibrary.git' }
  s.platform = :ios, '5.0'
  s.requires_arc = true
  s.source_files = 'POSInputStreamLibrary/*.{h,m}'
  s.frameworks = 'Foundation', 'AssetsLibrary'
end
