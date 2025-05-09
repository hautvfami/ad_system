import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../models/ad_config.dart';
import '../models/ad_types.dart';
import '../models/user_segment.dart';

/// Service that interfaces with Firebase Remote Config to fetch
/// dynamic ad settings.
///
/// This service allows for:
/// - Remotely updating ad unit IDs
/// - Adjusting frequency caps
/// - A/B testing different ad strategies
/// - Turning ads on/off remotely
class RemoteConfigService extends GetxService {
  final FirebaseRemoteConfig _remoteConfig;
  final Rx<AdConfig> _adConfig = AdConfig.defaultConfig().obs;
  final RxBool _isInitialized = false.obs;

  /// Public accessor for the current ad configuration
  AdConfig get adConfig => _adConfig.value;

  /// Whether remote config has been initialized
  bool get isInitialized => _isInitialized.value;

  /// Constructor
  RemoteConfigService({required FirebaseRemoteConfig remoteConfig})
      : _remoteConfig = remoteConfig;

  /// Initialize and fetch remote configuration
  Future<void> initialize() async {
    if (_isInitialized.value) return;

    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kReleaseMode
            ? const Duration(hours: 1)
            : Duration.zero, // Allow frequent fetches in debug
      ));

      // Set defaults
      await _remoteConfig.setDefaults({
        'ad_config': jsonEncode(_defaultConfigMap()),
      });

      // Fetch remote config
      await _remoteConfig.fetchAndActivate();

      // Parse the config
      _parseRemoteConfig();

      _isInitialized.value = true;
    } catch (e) {
      print('Failed to initialize remote config: $e');
    }
  }

  /// Force a refresh of the remote configuration
  Future<void> refreshConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _parseRemoteConfig();
    } catch (e) {
      print('Failed to refresh remote config: $e');
    }
  }

  /// Get individual ad configuration values with defaults
  bool get adsEnabled => _adConfig.value.adsEnabled;
  bool isAdTypeEnabled(AdType type) =>
      _adConfig.value.adTypesEnabled[type] ?? false;
  Map<String, String> getPlacementIds(AdType type) =>
      _adConfig.value.placementIds[type] ?? {};
  int getFrequencyCap(UserSegment segment, AdType type) =>
      _adConfig.value.segmentFrequencyCaps[segment]?[type] ?? 0;

  /// Parse the remote configuration into the AdConfig object
  void _parseRemoteConfig() {
    try {
      final configStr = _remoteConfig.getString('ad_config');
      if (configStr.isEmpty) return;

      final configMap = jsonDecode(configStr) as Map<String, dynamic>;

      // Parse general settings
      final adsEnabled = configMap['ads_enabled'] as bool? ?? true;
      final useTestAds = configMap['use_test_ads'] as bool? ?? !kReleaseMode;

      // Parse ad type enabled flags
      final adTypesEnabledMap = <AdType, bool>{};
      final adTypesEnabled =
          configMap['ad_types_enabled'] as Map<String, dynamic>? ?? {};
      for (final entry in adTypesEnabled.entries) {
        final adType = _stringToAdType(entry.key);
        if (adType != AdType.none) {
          adTypesEnabledMap[adType] = entry.value as bool? ?? false;
        }
      }

      // Parse placement IDs
      final placementIdsMap = <AdType, Map<String, String>>{};
      final placementIds =
          configMap['placement_ids'] as Map<String, dynamic>? ?? {};
      for (final entry in placementIds.entries) {
        final adType = _stringToAdType(entry.key);
        if (adType != AdType.none && entry.value is Map) {
          final platformIds = <String, String>{};
          for (final platform in (entry.value as Map).entries) {
            platformIds[platform.key] = platform.value.toString();
          }
          placementIdsMap[adType] = platformIds;
        }
      }

      // Parse frequency caps
      final segmentCapsMap = <UserSegment, Map<AdType, int>>{};
      final segmentCaps =
          configMap['segment_frequency_caps'] as Map<String, dynamic>? ?? {};
      for (final segmentEntry in segmentCaps.entries) {
        final segment = _stringToUserSegment(segmentEntry.key);
        if (segment != null && segmentEntry.value is Map) {
          final adTypeCaps = <AdType, int>{};
          for (final typeEntry in (segmentEntry.value as Map).entries) {
            final adType = _stringToAdType(typeEntry.key);
            if (adType != AdType.none) {
              adTypeCaps[adType] = typeEntry.value as int? ?? 0;
            }
          }
          segmentCapsMap[segment] = adTypeCaps;
        }
      }

      // Create updated config
      _adConfig.value = AdConfig(
        adsEnabled: adsEnabled,
        adTypesEnabled: adTypesEnabledMap,
        placementIds: placementIdsMap,
        useTestAds: useTestAds,
        segmentFrequencyCaps: segmentCapsMap,
        interstitialCooldownSeconds:
            configMap['interstitial_cooldown_seconds'] as int? ?? 60,
        appOpenAdCooldownSeconds:
            configMap['app_open_ad_cooldown_seconds'] as int? ?? 300,
        usePreCaching: configMap['use_pre_caching'] as bool? ?? true,
        showAdsInPremiumMode:
            configMap['show_ads_in_premium_mode'] as bool? ?? false,
        maxLoadRetries: configMap['max_load_retries'] as int? ?? 3,
        adLoadTimeout: configMap['ad_load_timeout'] as int? ?? 15000,
      );
    } catch (e) {
      print('Error parsing remote config: $e');
    }
  }

  /// Helper to convert string to AdType
  AdType _stringToAdType(String value) {
    switch (value.toLowerCase()) {
      case 'banner':
        return AdType.banner;
      case 'interstitial':
        return AdType.interstitial;
      case 'rewarded':
        return AdType.rewarded;
      case 'native':
        return AdType.native;
      case 'app_open':
      case 'appopen':
        return AdType.appOpen;
      default:
        return AdType.none;
    }
  }

  /// Helper to convert string to UserSegment
  UserSegment? _stringToUserSegment(String value) {
    switch (value.toLowerCase()) {
      case 'newbie':
        return UserSegment.newbie;
      case 'normal':
        return UserSegment.normal;
      case 'highvalue':
      case 'high_value':
        return UserSegment.highValue;
      case 'premium':
        return UserSegment.premium;
      default:
        return null;
    }
  }

  /// Default configuration as a map for remote config defaults
  Map<String, dynamic> _defaultConfigMap() {
    // Get default AdConfig and convert it to a map structure
    // that matches what we expect from Remote Config

    final config = AdConfig.defaultConfig();

    // Convert ad types enabled
    final adTypesEnabled = <String, bool>{};
    for (final entry in config.adTypesEnabled.entries) {
      adTypesEnabled[entry.key.toString().split('.').last] = entry.value;
    }

    // Convert placement IDs
    final placementIds = <String, Map<String, String>>{};
    for (final entry in config.placementIds.entries) {
      placementIds[entry.key.toString().split('.').last] = entry.value;
    }

    // Convert segment frequency caps
    final segmentCaps = <String, Map<String, int>>{};
    for (final segmentEntry in config.segmentFrequencyCaps.entries) {
      final adTypeCaps = <String, int>{};
      for (final typeEntry in segmentEntry.value.entries) {
        adTypeCaps[typeEntry.key.toString().split('.').last] = typeEntry.value;
      }
      segmentCaps[segmentEntry.key.toString().split('.').last] = adTypeCaps;
    }

    return {
      'ads_enabled': config.adsEnabled,
      'ad_types_enabled': adTypesEnabled,
      'placement_ids': placementIds,
      'use_test_ads': config.useTestAds,
      'segment_frequency_caps': segmentCaps,
      'interstitial_cooldown_seconds': config.interstitialCooldownSeconds,
      'app_open_ad_cooldown_seconds': config.appOpenAdCooldownSeconds,
      'use_pre_caching': config.usePreCaching,
      'show_ads_in_premium_mode': config.showAdsInPremiumMode,
      'max_load_retries': config.maxLoadRetries,
      'ad_load_timeout': config.adLoadTimeout,
    };
  }
}
