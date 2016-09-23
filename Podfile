# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'tessTest' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'TesseractOCRiOS', '4.0.0'
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod "PromiseKit", "~> 4.0"

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '3.0'
      end
    end
  end

  # Pods for tessTest

  target 'tessTestUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
