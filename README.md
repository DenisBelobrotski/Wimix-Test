# Wimix-Test
I'm using Xcode 9 and Swift 4.
## If you want to run this project:
1. Download this project.
2. Install [CocoaPods](https://cocoapods.org).
3. Include in project [Alamofire](https://github.com/Alamofire/Alamofire) and [Google Maps SDK](https://developers.google.com/maps/documentation/ios-sdk/start) using CocoaPods. My Podfile:
```ruby
use_frameworks!
target 'Wimix-Test' do
  pod 'GoogleMaps'
  pod 'Alamofire'
end
```
4. After installing close project and open ```Wimix-Test.xcworkspace``` (not ```Wimix-Test.xcodeproj```).
5. Clean (```Product~>Clean```) and run (```Product~>Run```) project.
