import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controllers/ad_analytics_controller.dart';
import '../models/ad_event.dart';
import '../models/ad_types.dart';
import '../models/user_segment.dart';
import '../services/ad_id_provider.dart';

/// Manager for native ads.
///
/// This class handles:
/// - Loading native ads
/// - Caching native ads for reuse
/// - Handling native ad events
/// - Providing metrics for native ad performance
class NativeAdManager extends GetxController {
  final AdAnalyticsController _analytics;

  // Cache of loaded native ads
  final _loadedNativeAds = <String, NativeAd>{};

  // Loading state
  final _isLoading = <String, bool>{}.obs;

  // Factory IDs for different native ad templates
  static const Map<String, String> _nativeAdFactories = {
    'small': 'smallNativeAdFactory',
    'medium': 'mediumNativeAdFactory',
    'large': 'largeNativeAdFactory',
    'custom': 'customNativeAdFactory',
  };

  /// Constructor
  NativeAdManager({required AdAnalyticsController analytics})
    : _analytics = analytics;

  @override
  void onClose() {
    // Dispose all loaded native ads
    for (final nativeAd in _loadedNativeAds.values) {
      nativeAd.dispose();
    }
    _loadedNativeAds.clear();
    super.onClose();
  }

  /// Check if a native ad is currently loading
  bool isAdLoading(String placementName) {
    return _isLoading[placementName] ?? false;
  }

  /// Load a native ad with the specified template
  Future<NativeAd?> loadNativeAd({
    required String placementName,
    String template = 'medium',
    bool useTestAds = !kReleaseMode,
    UserSegment? userSegment,
    Function(NativeAd ad)? onAdLoaded,
    Function(String error)? onAdFailedToLoad,
    Map<String, Object>? customOptions,
    BuildContext? context, // Add context parameter
    int retryCount = 0, // For retry logic
  }) async {
    // Check if we're already loading this ad
    if (_isLoading[placementName] == true) {
      debugPrint('NativeAdManager: Already loading ad for $placementName, skipping');
      return null;
    }

    // Maximum retry attempts
    const int maxRetries = 2;
    
    // Mark as loading
    _isLoading[placementName] = true;
    debugPrint('NativeAdManager: Loading native ad for $placementName (try ${retryCount+1}/${maxRetries+1})');

    // Get ad unit ID
    String adUnitId =
        placementName.contains('_')
            ? AdIdProvider.getCustomPlacementId(
              placementName: placementName,
              useTestAds: useTestAds,
            )
            : AdIdProvider.getAdUnitId(
              adType: AdType.native,
              useTestAds: useTestAds,
            );
            
    // Make sure we have a valid ad unit ID
    if (adUnitId.isEmpty) {
      // Log the error
      print('NativeAdManager: Empty ad unit ID for placement: $placementName');
      
      // Fall back to test ad unit ID
      adUnitId = AdIdProvider.getAdUnitId(
        adType: AdType.native, 
        useTestAds: true
      );
      
      if (adUnitId.isEmpty) {
        // Hard-code the Google test ID as a last resort
        adUnitId = Platform.isAndroid 
            ? 'ca-app-pub-3940256099942544/2247696110' 
            : 'ca-app-pub-3940256099942544/3986624511';
      }
    }

    // Get factory ID
    final factoryId =
        _nativeAdFactories[template.toLowerCase()] ??
        _nativeAdFactories['medium']!;

    // Create native ad
    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      customOptions: customOptions,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _loadedNativeAds[placementName] = ad as NativeAd;
          _isLoading[placementName] = false;

          // Track success event
          _analytics.trackAdEvent(
            AdEvent.loaded(
              AdType.native,
              adUnitId: adUnitId,
              userSegment: userSegment,
              isTestAd: useTestAds,
            ),
          );

          // Notify callback if provided
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _loadedNativeAds.remove(placementName);
          _isLoading[placementName] = false;

          // Track failure event
          _analytics.trackAdEvent(
            AdEvent.failed(
              AdType.native,
              adUnitId: adUnitId,
              error: error.message,
              errorCode: error.code,
              userSegment: userSegment,
              isTestAd: useTestAds,
            ),
          );

          // Notify callback if provided
          onAdFailedToLoad?.call(error.message);
        },
        onAdImpression: (ad) {
          _analytics.trackAdEvent(
            AdEvent.impression(
              AdType.native,
              adUnitId: adUnitId,
              userSegment: userSegment,
              isTestAd: useTestAds,
            ),
          );
        },
        onAdClicked: (ad) {
          _analytics.trackAdEvent(
            AdEvent.clicked(
              AdType.native,
              adUnitId: adUnitId,
              userSegment: userSegment,
              isTestAd: useTestAds,
            ),
          );
        },
      ),
    );

    // Track request event
    _analytics.trackAdEvent(
      AdEvent.requested(
        AdType.native,
        adUnitId: adUnitId,
        userSegment: userSegment,
        isTestAd: useTestAds,
      ),
    );

    try {
      // Load the native ad
      await nativeAd.load();
      debugPrint('NativeAdManager: Load call completed for $placementName');
      return nativeAd;
    } catch (e) {
      // Handle error
      debugPrint('NativeAdManager: Error loading native ad: $e');
      _isLoading[placementName] = false;
      
      // Try again with a different test ad unit ID if this is a test ad and we haven't reached max retries
      if (useTestAds && retryCount < 2) {
        onAdFailedToLoad?.call("Retrying with different ad unit ID...");
        
        // Use the hard-coded test ad unit ID for the retry
        return loadNativeAd(
          placementName: placementName,
          template: template,
          useTestAds: true,
          userSegment: userSegment,
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
          customOptions: customOptions,
          context: context,
          retryCount: retryCount + 1,
        );
      }
      
      onAdFailedToLoad?.call(e.toString());
      return null;
    }
  }

  /// Get a previously loaded native ad by placement name
  NativeAd? getNativeAd(String placementName) {
    return _loadedNativeAds[placementName];
  }

  /// Dispose a specific native ad
  void disposeNativeAd(String placementName) {
    final nativeAd = _loadedNativeAds[placementName];
    if (nativeAd != null) {
      nativeAd.dispose();
      _loadedNativeAds.remove(placementName);
    }
  }
}
