package com.example.example

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.android.gms.ads.MobileAds
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize the Mobile Ads SDK
        MobileAds.initialize(this) {}

        // Register the NativeAdFactories
        
        // Register medium native ad factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "mediumNativeAdFactory",
            MediumNativeAdFactory(context)
        )
        
        // Register small native ad factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "smallNativeAdFactory",
            SmallNativeAdFactory(context)
        )
        
        // Register large native ad factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "largeNativeAdFactory",
            LargeNativeAdFactory(context)
        )
        
        // Register custom native ad factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "customNativeAdFactory",
            CustomNativeAdFactory(context)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        
        // Unregister the factories when done
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "smallNativeAdFactory")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "mediumNativeAdFactory")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "largeNativeAdFactory")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "customNativeAdFactory")
    }
}
