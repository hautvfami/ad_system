import 'package:get/get.dart';

import '../models/ad_types.dart';
import '../models/user_segment.dart';

/// Controls ad frequency capping to ensure users don't see too many ads
/// in a single session or day.
class AdFrequencyController extends GetxController {
  // Ad counts for current session
  final _sessionAdCounts = <AdType, int>{
    AdType.banner: 0,
    AdType.native: 0,
    AdType.interstitial: 0,
    AdType.rewarded: 0,
    AdType.appOpen: 0,
  }.obs;

  // Ad counts for current day
  final _dailyAdCounts = <AdType, int>{
    AdType.banner: 0,
    AdType.native: 0,
    AdType.interstitial: 0,
    AdType.rewarded: 0,
    AdType.appOpen: 0,
  }.obs;

  // Last shown timestamps
  final _lastShownTime = <AdType, DateTime?>{
    AdType.banner: null,
    AdType.native: null,
    AdType.interstitial: null,
    AdType.rewarded: null,
    AdType.appOpen: null,
  }.obs;

  // Max limits (will be overridden by user segment)
  int maxInterstitialsPerDay = 8;
  int maxInterstitialsPerSession = 3;
  int interstitialCooldownSeconds = 120;
  int maxNativeAdsPerSession = 5;
  int maxRewardedPerSession = 10;

  @override
  void onInit() {
    super.onInit();
    _loadDailyCounts();
  }

  /// Check if we can show an interstitial based on frequency caps
  bool canShowInterstitial() {
    // Check daily cap
    if (_dailyAdCounts[AdType.interstitial]! >= maxInterstitialsPerDay) {
      return false;
    }

    // Check session cap
    if (_sessionAdCounts[AdType.interstitial]! >= maxInterstitialsPerSession) {
      return false;
    }

    // Check cooldown
    final lastShown = _lastShownTime[AdType.interstitial];
    if (lastShown != null) {
      final timeSince = DateTime.now().difference(lastShown);
      if (timeSince.inSeconds < interstitialCooldownSeconds) {
        return false;
      }
    }

    return true;
  }

  /// Check if we can show a native ad based on frequency caps
  bool canShowNativeAd() {
    // Check session cap
    if (_sessionAdCounts[AdType.native]! >= maxNativeAdsPerSession) {
      return false;
    }

    return true;
  }

  /// Check if we can show a rewarded ad based on frequency caps
  bool canShowRewardedAd() {
    // Check session cap - though rewarded ads are typically unlimited
    if (_sessionAdCounts[AdType.rewarded]! >= maxRewardedPerSession) {
      return false;
    }

    return true;
  }

  /// Increment ad count when an ad is shown
  void incrementAdCount(AdType type) {
    // Update session count
    _sessionAdCounts[type] = _sessionAdCounts[type]! + 1;

    // Update daily count
    _dailyAdCounts[type] = _dailyAdCounts[type]! + 1;

    // Update last shown time
    _lastShownTime[type] = DateTime.now();

    // Persist daily counts
    _saveDailyCounts();
  }

  /// Apply segment-specific settings
  void applySegmentSettings(UserSegment segment) {
    // Apply frequency settings from the user segment
    // This allows for personalized ad frequency
    // Implementation will depend on your UserSegment model
  }

  /// Reset session counts (call when app goes to background)
  void resetSessionCounts() {
    for (final type in _sessionAdCounts.keys) {
      _sessionAdCounts[type] = 0;
    }
  }

  /// Reset daily counts (call at midnight or app restart)
  void resetDailyCounts() {
    final today = DateTime.now().day;
    final lastResetDay = _getLastResetDay();

    if (today != lastResetDay) {
      for (final type in _dailyAdCounts.keys) {
        _dailyAdCounts[type] = 0;
      }
      _saveLastResetDay(today);
      _saveDailyCounts();
    }
  }

  /// Get the session counts for analytics
  Map<AdType, int> getSessionCounts() {
    return Map<AdType, int>.from(_sessionAdCounts);
  }

  /// Get the daily counts for analytics
  Map<AdType, int> getDailyCounts() {
    return Map<AdType, int>.from(_dailyAdCounts);
  }

  // Persistence methods (implement with your storage solution)
  Future<void> _loadDailyCounts() async {
    // Load daily counts from storage
    resetDailyCounts(); // Reset if needed
    // Implementation depends on your storage mechanism
  }

  Future<void> _saveDailyCounts() async {
    // Save daily counts to storage
    // Implementation depends on your storage mechanism
  }

  int _getLastResetDay() {
    // Get last reset day from storage
    // Implementation depends on your storage mechanism
    return DateTime.now().day; // Default to today if not found
  }

  Future<void> _saveLastResetDay(int day) async {
    // Save last reset day to storage
    // Implementation depends on your storage mechanism
  }
}
