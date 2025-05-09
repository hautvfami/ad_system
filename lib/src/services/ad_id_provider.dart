import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/ad_types.dart';

/// Service that provides ad unit IDs based on platform and environment.
///
/// This service centralizes the management of ad unit IDs:
/// - Provides correct IDs based on platform (iOS/Android)
/// - Handles test vs production ad IDs
/// - Makes it easy to update IDs in one place
class AdIdProvider {
  // Test ad IDs from Google
  static const Map<String, Map<AdType, String>> _testAdUnitIds = {
    'android': {
      AdType.banner: 'ca-app-pub-3940256099942544/6300978111',
      AdType.interstitial: 'ca-app-pub-3940256099942544/1033173712',
      AdType.rewarded: 'ca-app-pub-3940256099942544/5224354917',
      AdType.native: 'ca-app-pub-3940256099942544/2247696110',
      AdType.appOpen: 'ca-app-pub-3940256099942544/9257395921',
    },
    'ios': {
      AdType.banner: 'ca-app-pub-3940256099942544/2934735716',
      AdType.interstitial: 'ca-app-pub-3940256099942544/4411468910',
      AdType.rewarded: 'ca-app-pub-3940256099942544/1712485313',
      AdType.native: 'ca-app-pub-3940256099942544/3986624511',
      AdType.appOpen: 'ca-app-pub-3940256099942544/5662855259',
    },
  };

  // Production ad IDs - Replace with your actual ad IDs
  static const Map<String, Map<AdType, String>> _productionAdUnitIds = {
    'android': {
      AdType.banner: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      AdType.interstitial: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      AdType.rewarded: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      AdType.native: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      AdType.appOpen: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
    },
    'ios': {
      AdType.banner: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      AdType.interstitial: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      AdType.rewarded: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      AdType.native: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      AdType.appOpen: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
    },
  };

  // Custom ad IDs for specific placements (e.g. different banner locations)
  static const Map<String, Map<String, String>> _customPlacementIds = {
    'android': {
      'chat_bottom_banner': 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      'profile_native_ad': 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
    },
    'ios': {
      'chat_bottom_banner': 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
      'profile_native_ad': 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
    },
  };

  /// Get the platform name for ad ID lookup
  static String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'android'; // Default to Android for unknown platforms
  }

  /// Get the ad unit ID for the given ad type
  ///
  /// If useTestAds is true or we're in debug mode, returns test ad IDs.
  /// Otherwise returns production ad IDs.
  static String getAdUnitId({
    required AdType adType,
    bool useTestAds = !kReleaseMode,
  }) {
    if (adType == AdType.none) return '';

    final idMap = useTestAds ? _testAdUnitIds : _productionAdUnitIds;
    return idMap[_platform]?[adType] ?? '';
  }

  /// Get a custom ad unit ID for a specific placement
  static String getCustomPlacementId({
    required String placementName,
    bool useTestAds = !kReleaseMode,
  }) {
    // If using test ads, return a standard test ad ID based on
    // the convention that placement name contains the ad type
    if (useTestAds) {
      if (placementName.contains('banner')) {
        return getAdUnitId(adType: AdType.banner, useTestAds: true);
      } else if (placementName.contains('interstitial')) {
        return getAdUnitId(adType: AdType.interstitial, useTestAds: true);
      } else if (placementName.contains('rewarded')) {
        return getAdUnitId(adType: AdType.rewarded, useTestAds: true);
      } else if (placementName.contains('native')) {
        return getAdUnitId(adType: AdType.native, useTestAds: true);
      }
    }

    // Otherwise, return the custom placement ID if available
    return _customPlacementIds[_platform]?[placementName] ?? '';
  }
}
