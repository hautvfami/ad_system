import 'package:flutter/foundation.dart';

import 'ad_types.dart';
import 'user_segment.dart';

/// Configuration for the ad system.
///
/// This class holds the configuration settings for the ad system,
/// including placementIDs and behavior settings. Configuration can be
/// loaded from remote config or local defaults.
class AdConfig {
  /// Whether ads are enabled in the app
  final bool adsEnabled;

  /// Whether specific ad types are enabled
  final Map<AdType, bool> adTypesEnabled;

  /// AdMob placement IDs keyed by ad type and platform
  final Map<AdType, Map<String, String>> placementIds;

  /// Whether to use test ads
  final bool useTestAds;

  /// Per-segment ad frequency caps
  final Map<UserSegment, Map<AdType, int>> segmentFrequencyCaps;

  /// Global cooling periods between interstitials (in seconds)
  final int interstitialCooldownSeconds;

  /// Global cooling period for app open ads (in seconds)
  final int appOpenAdCooldownSeconds;

  /// Whether to use pre-caching for interstitial and rewarded ads
  final bool usePreCaching;

  /// Whether to show ads in premium mode (usually false except for certain ad types)
  final bool showAdsInPremiumMode;

  /// Maximum number of retries for failed ad loads
  final int maxLoadRetries;

  /// Timeout duration for ad loads (in milliseconds)
  final int adLoadTimeout;

  const AdConfig({
    this.adsEnabled = true,
    required this.adTypesEnabled,
    required this.placementIds,
    this.useTestAds = !kReleaseMode,
    required this.segmentFrequencyCaps,
    this.interstitialCooldownSeconds = 60,
    this.appOpenAdCooldownSeconds = 300,
    this.usePreCaching = true,
    this.showAdsInPremiumMode = false,
    this.maxLoadRetries = 3,
    this.adLoadTimeout = 15000,
  });

  /// Create a default configuration
  factory AdConfig.defaultConfig() {
    return AdConfig(
      adsEnabled: true,
      adTypesEnabled: {
        AdType.banner: true,
        AdType.interstitial: true,
        AdType.rewarded: true,
        AdType.native: true,
        AdType.appOpen: true,
      },
      placementIds: {
        AdType.banner: {
          'android': 'ca-app-pub-3940256099942544/6300978111', // Test ad ID
          'ios': 'ca-app-pub-3940256099942544/2934735716', // Test ad ID
        },
        AdType.interstitial: {
          'android': 'ca-app-pub-3940256099942544/1033173712', // Test ad ID
          'ios': 'ca-app-pub-3940256099942544/4411468910', // Test ad ID
        },
        AdType.rewarded: {
          'android': 'ca-app-pub-3940256099942544/5224354917', // Test ad ID
          'ios': 'ca-app-pub-3940256099942544/1712485313', // Test ad ID
        },
        AdType.native: {
          'android': 'ca-app-pub-3940256099942544/2247696110', // Test ad ID
          'ios': 'ca-app-pub-3940256099942544/3986624511', // Test ad ID
        },
        AdType.appOpen: {
          'android': 'ca-app-pub-3940256099942544/9257395921', // Test ad ID
          'ios': 'ca-app-pub-3940256099942544/5662855259', // Test ad ID
        },
      },
      segmentFrequencyCaps: {
        UserSegment.newbie: {
          AdType.interstitial: 2,
          AdType.native: 3,
          AdType.banner: 5,
          AdType.rewarded: 10,
          AdType.appOpen: 2,
        },
        UserSegment.normal: {
          AdType.interstitial: 5,
          AdType.native: 10,
          AdType.banner: 10,
          AdType.rewarded: 20,
          AdType.appOpen: 5,
        },
        UserSegment.highValue: {
          AdType.interstitial: 3,
          AdType.native: 5,
          AdType.banner: 5,
          AdType.rewarded: 15,
          AdType.appOpen: 3,
        },
        UserSegment.premium: {
          AdType.interstitial: 0,
          AdType.native: 0,
          AdType.banner: 0,
          AdType.rewarded: 5,
          AdType.appOpen: 0,
        },
      },
    );
  }

  /// Create a copy with overridden values
  AdConfig copyWith({
    bool? adsEnabled,
    Map<AdType, bool>? adTypesEnabled,
    Map<AdType, Map<String, String>>? placementIds,
    bool? useTestAds,
    Map<UserSegment, Map<AdType, int>>? segmentFrequencyCaps,
    int? interstitialCooldownSeconds,
    int? appOpenAdCooldownSeconds,
    bool? usePreCaching,
    bool? showAdsInPremiumMode,
    int? maxLoadRetries,
    int? adLoadTimeout,
  }) {
    return AdConfig(
      adsEnabled: adsEnabled ?? this.adsEnabled,
      adTypesEnabled: adTypesEnabled ?? this.adTypesEnabled,
      placementIds: placementIds ?? this.placementIds,
      useTestAds: useTestAds ?? this.useTestAds,
      segmentFrequencyCaps: segmentFrequencyCaps ?? this.segmentFrequencyCaps,
      interstitialCooldownSeconds:
          interstitialCooldownSeconds ?? this.interstitialCooldownSeconds,
      appOpenAdCooldownSeconds:
          appOpenAdCooldownSeconds ?? this.appOpenAdCooldownSeconds,
      usePreCaching: usePreCaching ?? this.usePreCaching,
      showAdsInPremiumMode: showAdsInPremiumMode ?? this.showAdsInPremiumMode,
      maxLoadRetries: maxLoadRetries ?? this.maxLoadRetries,
      adLoadTimeout: adLoadTimeout ?? this.adLoadTimeout,
    );
  }
}
