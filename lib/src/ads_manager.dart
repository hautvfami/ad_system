import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import './controllers/ad_analytics_controller.dart';
import './controllers/ad_analyzer_controller.dart';
import './controllers/ad_controller.dart';
import './controllers/ad_frequency_controller.dart';
import './controllers/ad_segmentation_controller.dart';
import './managers/banner_manager.dart';
import './managers/interstitial_manager.dart';
import './managers/native_ad_manager.dart';
import './managers/rewarded_manager.dart';
import './models/ad_config.dart';
import './models/ad_types.dart';
import './models/user_segment.dart';
import './services/ad_initializer.dart';
import './services/ad_service.dart';
import './services/analytics_service.dart';
import './services/remote_config_service.dart';
import './services/revenue_attribution.dart';

/// Main entry point for the ad system - a facade that provides easy access
/// to all ad functionality while hiding implementation details.
///
/// Usage:
/// ```dart
/// // In main.dart or app initialization
/// await AdsManager.instance.initialize();
///
/// // In screens/widgets
/// AdsManager.instance.showInterstitialAd();
/// ```
class AdsManager {
  // Singleton instance
  static final AdsManager instance = AdsManager._();

  // Private constructor
  AdsManager._();

  // Services and controllers
  late AdController _adController;
  late AdService _adService;
  late AnalyticsService _analyticsService;
  late AdFrequencyController _frequencyController;
  late AdSegmentationController _segmentationController;
  late AdAnalyticsController _analyticsController;
  late AdAnalyzer _adAnalyzer;
  late RemoteConfigService _remoteConfigService;
  late AdInitializer _adInitializer;
  late RevenueAttribution _revenueAttribution;
  late CohortAnalysis _cohortAnalysis;

  // Specialized managers
  late BannerManager _bannerManager;
  late InterstitialManager _interstitialManager;
  late RewardedManager _rewardedManager;
  late NativeAdManager _nativeAdManager;

  // Flag to track initialization
  bool _isInitialized = false;

  /// Determines if the ad system has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the ad system
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Register Firebase services first
    final FirebaseRemoteConfig? firebaseRemoteConfig =
        await _initFirebaseServices();

    // Register analytics service
    if (!Get.isRegistered<AnalyticsService>()) {
      final analytics = Get.put(
        AnalyticsService(firebaseAnalytics: FirebaseAnalytics.instance),
        permanent: true,
      );
      await analytics.initialize();
    }

    // Register core controllers
    if (!Get.isRegistered<AdFrequencyController>()) {
      Get.put(AdFrequencyController(), permanent: true);
    }

    if (!Get.isRegistered<AdSegmentationController>()) {
      Get.put(AdSegmentationController(), permanent: true);
    }

    if (!Get.isRegistered<RemoteConfigService>()) {
      Get.put(
        RemoteConfigService(remoteConfig: firebaseRemoteConfig!),
        permanent: true,
      );
    }

    if (!Get.isRegistered<AdAnalyticsController>()) {
      final analytics = Get.find<AnalyticsService>();
      Get.put(AdAnalyticsController(analytics: analytics), permanent: true);
    }

    // Register revenue optimization services
    if (!Get.isRegistered<AdAnalyzer>()) {
      Get.put(AdAnalyzer(), permanent: true);
    }

    if (!Get.isRegistered<RevenueAttribution>()) {
      Get.put(RevenueAttribution(), permanent: true);
    }

    if (!Get.isRegistered<CohortAnalysis>()) {
      Get.put(CohortAnalysis(), permanent: true);
    }

    // Register initialization service
    if (!Get.isRegistered<AdInitializer>()) {
      final config = AdConfig.defaultConfig(); // Default config to start with
      Get.put(AdInitializer(config: config), permanent: true);
    }

    // Register ad type managers
    if (!Get.isRegistered<BannerManager>()) {
      final analytics = Get.find<AdAnalyticsController>();
      _bannerManager = Get.put(
        BannerManager(analytics: analytics),
        permanent: true,
      );
    }

    if (!Get.isRegistered<InterstitialManager>()) {
      final analytics = Get.find<AdAnalyticsController>();
      _interstitialManager = Get.put(
        InterstitialManager(analytics: analytics),
        permanent: true,
      );
    }

    if (!Get.isRegistered<RewardedManager>()) {
      final analytics = Get.find<AdAnalyticsController>();
      _rewardedManager = Get.put(
        RewardedManager(analytics: analytics),
        permanent: true,
      );
    }

    if (!Get.isRegistered<NativeAdManager>()) {
      final analytics = Get.find<AdAnalyticsController>();
      _nativeAdManager = Get.put(
        NativeAdManager(analytics: analytics),
        permanent: true,
      );
    }

    // Finally register the AdController that will use all of the above
    if (!Get.isRegistered<AdController>()) {
      Get.put(AdController(), permanent: true);
    }

    if (!Get.isRegistered<AdService>()) {
      Get.put(AdService(), permanent: true);
    }

    // Get references to services and controllers
    _analyticsService = Get.find<AnalyticsService>();
    _frequencyController = Get.find<AdFrequencyController>();
    _segmentationController = Get.find<AdSegmentationController>();
    _analyticsController = Get.find<AdAnalyticsController>();
    _adAnalyzer = Get.find<AdAnalyzer>();
    _remoteConfigService = Get.find<RemoteConfigService>();
    _adInitializer = Get.find<AdInitializer>();
    _revenueAttribution = Get.find<RevenueAttribution>();
    _cohortAnalysis = Get.find<CohortAnalysis>();

    _adController = Get.find<AdController>();
    _adService = Get.find<AdService>();

    // Initialize ad service and related components
    await _adInitializer.initialize();
    await _remoteConfigService.initialize();

    // Apply remote config to ad system
    _applyRemoteConfig();

    _isInitialized = true;
  }

  /// Initialize Firebase services needed for the ad system
  Future<FirebaseRemoteConfig?> _initFirebaseServices() async {
    try {
      // Initialize Firebase Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Set fetch settings
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval:
              kDebugMode
                  ? Duration
                      .zero // Always fetch in debug mode
                  : const Duration(hours: 1),
        ),
      );

      return remoteConfig;
    } catch (e) {
      print('Error initializing Firebase services: $e');
      return null;
    }
  }

  /// Apply configuration from remote config
  void _applyRemoteConfig() {
    final adConfig = _remoteConfigService.adConfig;

    // Update ad initializer
    _adInitializer.updateConfig(adConfig);

    // Update frequency controller
    for (final segment in adConfig.segmentFrequencyCaps.keys) {
      final caps = adConfig.segmentFrequencyCaps[segment];
      if (caps != null) {
        _frequencyController.applySegmentSettings(segment);
      }
    }
  }

  /// Shows an interstitial ad if available and returns whether it was shown
  Future<bool> showInterstitialAd({
    String placementName = 'default',
    Function()? onAdDismissed,
    Function(String error)? onAdFailedToShow,
  }) async {
    try {
      _requireInitialization();
      print('[AdsManager] Initialization check passed.');

      // Check if ad should be shown based on frequency caps and segmentation
      if (!_canShowAdType(AdType.interstitial)) {
        final error = 'Ad not allowed by frequency or segmentation rules';
        print('[AdsManager] $error');
        if (onAdFailedToShow != null) {
          onAdFailedToShow(error);
        }
        return false;
      }

      // Get user segment for analytics
      final userSegment = _segmentationController.currentSegment.value;
      print('[AdsManager] User segment: $userSegment');

      // Show the ad using the specialized manager
      final result = await _interstitialManager.showInterstitial(
        placementName: placementName,
        userSegment: userSegment,
        onAdDismissed: () {
          print('[AdsManager] Interstitial ad dismissed.');
          // Update frequency counter
          _frequencyController.incrementAdCount(AdType.interstitial);
          // Re-evaluate user segment
          _segmentationController.evaluateSegmentChange();

          if (onAdDismissed != null) {
            onAdDismissed();
          }
        },
        onAdFailedToShow: (error) {
          print('[AdsManager] Failed to show interstitial ad: $error');
          if (onAdFailedToShow != null) {
            onAdFailedToShow(error);
          }
        },
      );

      print('[AdsManager] Interstitial ad show result: $result');
      return result;
    } catch (e, stackTrace) {
      print('[AdsManager] Exception in showInterstitialAd: $e');
      print(stackTrace);
      if (onAdFailedToShow != null) {
        onAdFailedToShow(e.toString());
      }
      return false;
    }
  }

  /// Shows a rewarded ad if available
  Future<bool> showRewardedAd({
    String placementName = 'default',
    required Function(int amount, String type) onRewarded,
    Function()? onAdDismissed,
    Function(String error)? onAdFailedToShow,
  }) async {
    _requireInitialization();

    // Check if ad should be shown (less restrictive for rewarded ads)
    if (!_frequencyController.canShowRewardedAd()) {
      if (onAdFailedToShow != null) {
        onAdFailedToShow('Exceeded maximum rewarded ads allowed');
      }
      return false;
    }

    // Get user segment for analytics
    final userSegment = _segmentationController.currentSegment.value;

    // Show the ad using the specialized manager
    final result = await _rewardedManager.showRewarded(
      placementName: placementName,
      userSegment: userSegment,
      onRewarded: (amount, type) {
        // Update frequency counter
        _frequencyController.incrementAdCount(AdType.rewarded);
        // Re-evaluate user segment
        _segmentationController.evaluateSegmentChange();

        onRewarded(amount, type);
      },
      onAdDismissed: onAdDismissed,
      onAdFailedToShow: onAdFailedToShow,
    );

    return result;
  }

  /// Shows an app open ad if available
  Future<bool> showAppOpenAd() async {
    _requireInitialization();

    // Placeholder - App Open ad implementation would go here
    // We would typically implement this using AdMob's AppOpenAd
    // For now, we'll just use the interstitial manager as an example

    if (!_canShowAdType(AdType.appOpen)) {
      return false;
    }

    // Use interstitial manager as a placeholder for app open ad manager
    return await _interstitialManager.showInterstitial(
      placementName: 'app_open',
      onAdDismissed: () {
        _frequencyController.incrementAdCount(AdType.appOpen);
      },
    );
  }

  /// Load and show a native ad
  Future<dynamic> loadNativeAd({
    required String placementName,
    String template = 'medium',
    Function(dynamic ad)? onAdLoaded,
    Function(String error)? onAdFailedToLoad,
  }) async {
    _requireInitialization();

    // Check if ad should be shown
    if (!_canShowAdType(AdType.native)) {
      if (onAdFailedToLoad != null) {
        onAdFailedToLoad(
          'Native ad not allowed by frequency or segmentation rules',
        );
      }
      return null;
    }

    // Get user segment for analytics
    final userSegment = _segmentationController.currentSegment.value;

    // Load the ad using the specialized manager
    final ad = await _nativeAdManager.loadNativeAd(
      placementName: placementName,
      template: template,
      userSegment: userSegment,
      onAdLoaded: (ad) {
        _frequencyController.incrementAdCount(AdType.native);
        if (onAdLoaded != null) {
          onAdLoaded(ad);
        }
      },
      onAdFailedToLoad: onAdFailedToLoad,
    );

    return ad;
  }

  /// Loads an interstitial ad for future display
  Future<bool> loadInterstitialAd({
    String placementName = 'default',
    Function()? onAdLoaded,
    Function(String error)? onAdFailedToLoad,
  }) async {
    try {
      _requireInitialization();
      print(
        '[AdsManager] Loading interstitial ad for placement: $placementName',
      );

      // Check if ads are allowed for this user
      if (_adController.isPremiumUser.value) {
        final error = 'Premium users don\'t see ads';
        print('[AdsManager] $error');
        if (onAdFailedToLoad != null) {
          onAdFailedToLoad(error);
        }
        return false;
      }

      // Get user segment for analytics
      final userSegment = _segmentationController.currentSegment.value;

      // Load the ad using the specialized manager
      final result = await _interstitialManager.loadInterstitial(
        placementName: placementName,
        userSegment: userSegment,
      );

      if (result) {
        print('[AdsManager] Interstitial ad loaded successfully');
        if (onAdLoaded != null) {
          onAdLoaded();
        }
      } else if (onAdFailedToLoad != null) {
        onAdFailedToLoad('Failed to load interstitial ad');
      }

      return result;
    } catch (e, stackTrace) {
      print('[AdsManager] Exception in loadInterstitialAd: $e');
      print(stackTrace);
      if (onAdFailedToLoad != null) {
        onAdFailedToLoad(e.toString());
      }
      return false;
    }
  }

  /// Checks if the interstitial ad is loaded
  bool get isInterstitialAdLoaded {
    _requireInitialization();
    return _interstitialManager.isAdLoaded;
  }

  /// Check if an ad type can be shown based on frequency and segmentation
  bool _canShowAdType(AdType type) {
    // First, check premium status
    if (_adController.isPremiumUser.value) {
      return false;
    }

    // Next, check if it's an ad-free session
    if (_adController.isAdFreeSession.value) {
      return false;
    }

    // Check frequency capping
    switch (type) {
      case AdType.interstitial:
        return _frequencyController.canShowInterstitial() &&
            _segmentationController.shouldShowInterstitial();
      case AdType.native:
        return _frequencyController.canShowNativeAd() &&
            _segmentationController.shouldShowNativeAd();
      case AdType.banner:
        return _segmentationController.shouldShowBannerAd();
      default:
        return true;
    }
  }

  /// Sets whether the user has premium access (no ads)
  void setPremiumUser(bool isPremium) {
    _requireInitialization();
    _adController.setPremiumUser(isPremium);

    // Update the segmentation controller
    _segmentationController.updatePremiumStatus(isPremium);
  }

  /// Makes the current session ad-free (useful after purchases)
  void setAdFreeSession(bool isAdFree) {
    _requireInitialization();
    _adController.setAdFreeSession(isAdFree);
  }

  /// Sets the A/B test group for the user
  void setAbTestGroup(String group) {
    _requireInitialization();
    _adController.setAbTestGroup(group);
  }

  /// Updates session settings with new values from remote config
  void updateAdSettings({
    int? maxInterstitialPerSession,
    int? maxRewardedPerSession,
    int? minSecondsBetweenInterstitials,
  }) {
    _requireInitialization();

    if (maxInterstitialPerSession != null) {
      _adController.maxInterstitialPerSession.value = maxInterstitialPerSession;
    }

    if (maxRewardedPerSession != null) {
      _adController.maxRewardedPerSession.value = maxRewardedPerSession;
    }

    if (minSecondsBetweenInterstitials != null) {
      _adController.minSecondsBetweenInterstitials.value =
          minSecondsBetweenInterstitials;
    }
  }

  /// Updates eCPM data with recent values
  void updateEcpmData(Map<AdType, double> newData) {
    _requireInitialization();

    // Update in main controller
    _adController.updateEcpmData(newData);

    // Also update in analytics controller
    for (final entry in newData.entries) {
      _analyticsController.updateEcpm(entry.key, entry.value);
    }
  }

  /// Force remote config refresh
  Future<void> refreshRemoteConfig() async {
    _requireInitialization();
    await _remoteConfigService.refreshConfig();
    _applyRemoteConfig();
  }

  /// Resets session data (call when app is put in background)
  void resetSessionData() {
    if (!_isInitialized) return;

    // Reset data in controllers
    _adController.resetSessionData();
    _frequencyController.resetSessionCounts();
    _analyticsController.resetSessionMetrics();
  }

  /// Get analytics data for reporting
  Map<String, dynamic> getAnalyticsData() {
    _requireInitialization();

    return {
      'impressions': _analyticsController.getImpressions(),
      'clicks': _analyticsController.getClicks(),
      'ctr': _analyticsController.getOverallCtr(),
      'fillRate': _analyticsController.getFillRate(),
      'showRate': _analyticsController.getShowRate(),
      'estimatedRevenue': _analyticsController.getEstimatedRevenue(),
    };
  }

  /// Record a completed user action (for segmentation)
  void recordCompletedAction() {
    _requireInitialization();
    _segmentationController.recordCompletedAction();
  }

  /// Record an in-app purchase (for segmentation)
  void recordPurchase(double amount) {
    _requireInitialization();
    _segmentationController.recordPurchase(amount);
  }

  /// Checks if an ad can be shown based on frequency caps and other rules
  bool canShowAd(AdType type) {
    _requireInitialization();
    return _canShowAdType(type);
  }

  /// Force shows an interstitial ad by bypassing frequency and segmentation rules (USE FOR TESTING ONLY)
  Future<bool> forceShowInterstitialAd({
    String placementName = 'default',
    Function()? onAdDismissed,
    Function(String error)? onAdFailedToShow,
  }) async {
    try {
      _requireInitialization();
      print(
        '[AdsManager] Force showing interstitial ad, bypassing frequency and segmentation rules',
      );

      // Get user segment for analytics
      final userSegment = _segmentationController.currentSegment.value;

      // Show the ad using the specialized manager
      final result = await _interstitialManager.showInterstitial(
        placementName: placementName,
        userSegment: userSegment,
        onAdDismissed: () {
          if (onAdDismissed != null) {
            onAdDismissed();
          }
        },
        onAdFailedToShow: (error) {
          print('[AdsManager] Failed to force show interstitial ad: $error');
          if (onAdFailedToShow != null) {
            onAdFailedToShow(error);
          }
        },
      );

      print('[AdsManager] Force interstitial ad result: $result');
      return result;
    } catch (e, stackTrace) {
      print('[AdsManager] Exception in forceShowInterstitialAd: $e');
      print(stackTrace);
      if (onAdFailedToShow != null) {
        onAdFailedToShow(e.toString());
      }
      return false;
    }
  }

  /// TEST MODE: Tăng số phiên người dùng (chỉ sử dụng cho mục đích kiểm thử)
  void incrementUserSessions() {
    _requireInitialization();
    _segmentationController.userSessionsCount.value += 1;
    print(
      '[AdsManager] TEST MODE: Đã tăng số phiên người dùng lên ${_segmentationController.userSessionsCount.value}',
    );
    // Re-evaluate user segment after changing session count
    _segmentationController.evaluateSegmentChange();
  }

  /// TEST MODE: Thay đổi phân đoạn người dùng (chỉ sử dụng cho mục đích kiểm thử)
  void setUserSegment(UserSegment segment) {
    _requireInitialization();
    _segmentationController.currentSegment.value = segment;
    print(
      '[AdsManager] TEST MODE: Đã chuyển người dùng sang phân đoạn ${segment.toString()}',
    );
  }

  /// DEBUG: In thông tin chi tiết về các giới hạn quảng cáo
  void printAdDebugInfo(AdType type) {
    if (!_isInitialized) {
      print('[AdsManager] DEBUG: System not initialized yet');
      return;
    }

    print('\n==== ADS DEBUG INFO: ${type.toString()} ====');
    print('- isPremiumUser: ${_adController.isPremiumUser.value}');
    print('- isAdFreeSession: ${_adController.isAdFreeSession.value}');
    print('- User segment: ${_segmentationController.currentSegment.value}');
    print(
      '- User sessions count: ${_segmentationController.userSessionsCount.value}',
    );
    print('- Can show this ad type: ${_canShowAdType(type)}');

    switch (type) {
      case AdType.interstitial:
        print(
          '- Max interstitials per day: ${_frequencyController.maxInterstitialsPerDay}',
        );
        print(
          '- Max interstitials per session: ${_frequencyController.maxInterstitialsPerSession}',
        );
        print(
          '- Cooldown seconds: ${_frequencyController.interstitialCooldownSeconds}',
        );
        print(
          '- Should show interstitial (by segment): ${_segmentationController.shouldShowInterstitial()}',
        );
        print(
          '- Can show interstitial (by frequency): ${_frequencyController.canShowInterstitial()}',
        );
        break;
      case AdType.rewarded:
        print(
          '- Max rewarded per session: ${_frequencyController.maxRewardedPerSession}',
        );
        print(
          '- Can show rewarded (by frequency): ${_frequencyController.canShowRewardedAd()}',
        );
        break;
      case AdType.native:
        print(
          '- Max native ads per session: ${_frequencyController.maxNativeAdsPerSession}',
        );
        print(
          '- Should show native ad (by segment): ${_segmentationController.shouldShowNativeAd()}',
        );
        print(
          '- Can show native ad (by frequency): ${_frequencyController.canShowNativeAd()}',
        );
        break;
      case AdType.banner:
        print(
          '- Should show banner (by segment): ${_segmentationController.shouldShowBannerAd()}',
        );
        break;
      default:
        break;
    }
    print('===============================\n');
  }

  /// Ensures the ad system is initialized before operations
  void _requireInitialization() {
    if (!_isInitialized) {
      throw StateError(
        'Ad system not initialized. Call AdsManager.instance.initialize() first.',
      );
    }
  }
}
