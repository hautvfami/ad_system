import Flutter
import UIKit
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Mobile Ads SDK
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    
    // Register native ad factories
    let registrar = self.registrar(forPlugin: "GoogleMobileAdsPlugin")!
    
    // Register small native ad factory
    let smallNativeAdFactory = SmallNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      registrar, factoryId: "smallNativeAdFactory", nativeAdFactory: smallNativeAdFactory)
      
    // Register medium native ad factory
    let mediumNativeAdFactory = MediumNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      registrar, factoryId: "mediumNativeAdFactory", nativeAdFactory: mediumNativeAdFactory)
      
    // Register large native ad factory
    let largeNativeAdFactory = LargeNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      registrar, factoryId: "largeNativeAdFactory", nativeAdFactory: largeNativeAdFactory)
      
    // Register custom native ad factory
    let customNativeAdFactory = CustomNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      registrar, factoryId: "customNativeAdFactory", nativeAdFactory: customNativeAdFactory)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Unregister factories when terminating
    let registrar = self.registrar(forPlugin: "GoogleMobileAdsPlugin")!
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(registrar, factoryId: "smallNativeAdFactory")
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(registrar, factoryId: "mediumNativeAdFactory")
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(registrar, factoryId: "largeNativeAdFactory")
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(registrar, factoryId: "customNativeAdFactory")
  }
}
