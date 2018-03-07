# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

plugin 'cocoapods-keys', {
  :project => "Pigeon",
  :target => "Pigeon-iOS",
  :keys => ["OpenGraphIOAPIKey"]
}

target 'Pigeon-iOS' do
  platform :ios, '11.0'
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Pigeon
  pod 'GoogleAPIClientForREST/Calendar', '~> 1.3.1'
  pod 'GoogleSignIn', '~> 4.1.1'
  pod 'HockeySDK'

  target 'AddCalendarAction' do
  end

  target 'Pigeon-iOSTests' do
    inherit! :search_paths
    # Pods for testing
  end
  

end
