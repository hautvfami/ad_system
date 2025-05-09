import 'package:flutter/foundation.dart';
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
  }) async {
    // Check if we're already loading this ad
    if (_isLoading[placementName] == true) {
      return null;
    }

    // Mark as loading
    _isLoading[placementName] = true;

    // Get ad unit ID
    final adUnitId = placementName.contains('_')
        ? AdIdProvider.getCustomPlacementId(
            placementName: placementName,
            useTestAds: useTestAds,
          )
        : AdIdProvider.getAdUnitId(
            adType: AdType.native,
            useTestAds: useTestAds,
          );

    // Get factory ID
    final factoryId = _nativeAdFactories[template.toLowerCase()] ??
        _nativeAdFactories['medium']!;

    // Create native ad
    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _loadedNativeAds[placementName] = ad as NativeAd;
          _isLoading[placementName] = false;

          // Track success event
          _analytics.trackAdEvent(AdEvent.loaded(
            AdType.native,
            adUnitId: adUnitId,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));

          // Notify callback if provided
          onAdLoaded?.call(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _loadedNativeAds.remove(placementName);
          _isLoading[placementName] = false;

          // Track failure event
          _analytics.trackAdEvent(AdEvent.failed(
            AdType.native,
            adUnitId: adUnitId,
            error: error.message,
            errorCode: error.code,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));

          // Notify callback if provided
          onAdFailedToLoad?.call(error.message);
        },
        onAdImpression: (ad) {
          _analytics.trackAdEvent(AdEvent.impression(
            AdType.native,
            adUnitId: adUnitId,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));
        },
        onAdClicked: (ad) {
          _analytics.trackAdEvent(AdEvent.clicked(
            AdType.native,
            adUnitId: adUnitId,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));
        },
      ),
    );

    // Track request event
    _analytics.trackAdEvent(AdEvent.requested(
      AdType.native,
      adUnitId: adUnitId,
      userSegment: userSegment,
      isTestAd: useTestAds,
    ));

    try {
      // Load the native ad
      await nativeAd.load();
      return nativeAd;
    } catch (e) {
      // Handle error
      print('Error loading native ad: $e');
      _isLoading[placementName] = false;
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
