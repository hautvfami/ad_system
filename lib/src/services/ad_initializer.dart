import 'dart:io';

import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/ad_config.dart';

/// Service responsible for initializing the ad SDKs and preparing the ad system.
///
/// This service handles:
/// - Loading and initializing the Google Mobile Ads SDK
/// - Setting up test devices
/// - Configuring ad settings (e.g., tags for child-directed settings, max ad content rating)
class AdInitializer extends GetxService {
  final RxBool _isInitialized = false.obs;
  final RxBool _isInitializing = false.obs;
  AdConfig _config;

  /// Whether the ad SDKs are initialized
  bool get isInitialized => _isInitialized.value;

  /// Whether the ad SDKs are currently initializing
  bool get isInitializing => _isInitializing.value;

  AdInitializer({required AdConfig config}) : _config = config;

  /// Update config settings
  void updateConfig(AdConfig newConfig) {
    _config = newConfig;
  }

  /// Initialize the ad SDKs and prepare for ad displays
  Future<void> initialize() async {
    if (_isInitialized.value || _isInitializing.value) return;

    _isInitializing.value = true;

    try {
      // Initialize Google Mobile Ads SDK
      final status = await MobileAds.instance.initialize();

      // Configure request configuration, including test device IDs
      if (_config.useTestAds) {
        await _setupTestConfiguration();
      }

      // Log initialization results
      print('Ad SDK initialization complete. ${status.adapterStatuses}');

      // Mark initialization as complete
      _isInitialized.value = true;
    } catch (e) {
      print('Failed to initialize Ad SDKs: $e');
    } finally {
      _isInitializing.value = false;
    }
  }

  /// Setup test configuration for development
  Future<void> _setupTestConfiguration() async {
    // Add test device IDs if available
    final testDeviceIds = _getTestDeviceIds();

    if (testDeviceIds.isNotEmpty) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
    }
  }

  /// Get test device IDs for development
  List<String> _getTestDeviceIds() {
    // These should ideally come from a config file or environment
    // Using only sample test ID for now
    return ['SAMPLE-TEST-DEVICE-ID'];
  }

  /// Configure child-directed settings (COPPA compliance)
  void setTagForChildDirectedTreatment(bool childDirected) {
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: childDirected
            ? TagForChildDirectedTreatment.yes
            : TagForChildDirectedTreatment.no,
      ),
    );
  }

  /// Set maximum ad content rating (G, PG, T, MA)
  void setMaxAdContentRating(String rating) {
    // Valid values: G, PG, T, MA
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: rating),
    );
  }
}
