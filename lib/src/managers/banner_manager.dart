import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controllers/ad_analytics_controller.dart';
import '../models/ad_event.dart';
import '../models/ad_types.dart';
import '../models/user_segment.dart';
import '../services/ad_id_provider.dart';

/// Manager for banner ads.
///
/// This class handles:
/// - Loading banner ads
/// - Caching banners for reuse
/// - Listening to banner ad events
/// - Providing metrics for banner ad performance
class BannerManager extends GetxController {
  final AdAnalyticsController _analytics;

  // Cache of loaded banner ads
  final _loadedBanners = <String, BannerAd>{};

  // Banner ad sizes
  static const Map<String, AdSize> _bannerSizes = {
    'standard': AdSize.banner, // 320x50
    'large': AdSize.largeBanner, // 320x100
    'medium_rectangle': AdSize.mediumRectangle, // 300x250
    'full_banner': AdSize.fullBanner, // 468x60
    'leaderboard': AdSize.leaderboard, // 728x90
  };

  BannerManager({required AdAnalyticsController analytics})
      : _analytics = analytics;

  @override
  void onClose() {
    // Dispose all loaded banners
    for (final banner in _loadedBanners.values) {
      banner.dispose();
    }
    _loadedBanners.clear();
    super.onClose();
  }

  /// Load a banner ad with the specified size
  Future<BannerAd?> loadBanner({
    required String placementName,
    String size = 'standard',
    bool useTestAds = !kReleaseMode,
    UserSegment? userSegment,
  }) async {
    // Get ad unit ID
    final adUnitId = placementName.contains('_')
        ? AdIdProvider.getCustomPlacementId(
            placementName: placementName,
            useTestAds: useTestAds,
          )
        : AdIdProvider.getAdUnitId(
            adType: AdType.banner,
            useTestAds: useTestAds,
          );

    // Get banner size
    final adSize = _bannerSizes[size.toLowerCase()] ?? AdSize.banner;

    // Create banner ad
    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _loadedBanners[placementName] = ad as BannerAd;

          // Track success event
          _analytics.trackAdEvent(AdEvent.loaded(
            AdType.banner,
            adUnitId: adUnitId,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _loadedBanners.remove(placementName);

          // Track failure event
          _analytics.trackAdEvent(AdEvent.failed(
            AdType.banner,
            adUnitId: adUnitId,
            error: error.message,
            errorCode: error.code,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));
        },
        onAdImpression: (ad) {
          _analytics.trackAdEvent(AdEvent.impression(
            AdType.banner,
            adUnitId: adUnitId,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));
        },
        onAdClicked: (ad) {
          _analytics.trackAdEvent(AdEvent.clicked(
            AdType.banner,
            adUnitId: adUnitId,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));
        },
      ),
    );

    // Track request event
    _analytics.trackAdEvent(AdEvent.requested(
      AdType.banner,
      adUnitId: adUnitId,
      userSegment: userSegment,
      isTestAd: useTestAds,
    ));

    try {
      // Load the banner ad
      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      // Handle error
      print('Error loading banner ad: $e');
      return null;
    }
  }

  /// Get a previously loaded banner ad by placement name
  BannerAd? getBanner(String placementName) {
    return _loadedBanners[placementName];
  }

  /// Dispose a specific banner ad
  void disposeBanner(String placementName) {
    final banner = _loadedBanners[placementName];
    if (banner != null) {
      banner.dispose();
      _loadedBanners.remove(placementName);
    }
  }

  /// Get banner ad size dimensions
  static AdSize getBannerSize(String size) {
    return _bannerSizes[size.toLowerCase()] ?? AdSize.banner;
  }

  /// Get the height of a banner in logical pixels
  static double getBannerHeight(String size) {
    final adSize = _bannerSizes[size.toLowerCase()] ?? AdSize.banner;
    return adSize.height.toDouble();
  }

  /// Get the width of a banner in logical pixels
  static double getBannerWidth(String size) {
    final adSize = _bannerSizes[size.toLowerCase()] ?? AdSize.banner;
    // Use adaptive width for full-width banners
    if (adSize == AdSize.banner || adSize == AdSize.largeBanner) {
      return double.infinity; // Full width
    }
    return adSize.width.toDouble();
  }
}
