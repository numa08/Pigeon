# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

plugin 'cocoapods-keys', {
  :project => "Pigeon",
  :target => "Pigeon",
  :keys => ["OpenGraphIOAPIKey"]
}

target 'Pigeon' do
  platform :ios, '11.0'
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Pigeon
  pod 'GoogleAPIClientForREST/Calendar', '~> 1.3.1'
  pod 'GoogleSignIn', '~> 4.1.1'


  target 'AddCalendarAction' do
  end

  target 'PigeonTests' do
    inherit! :search_paths
    # Pods for testing
  end
  

end
