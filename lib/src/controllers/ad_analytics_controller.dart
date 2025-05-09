import 'package:get/get.dart';

import '../models/ad_event.dart';
import '../models/ad_types.dart';
import '../services/analytics_service.dart';

/// Controls analytics tracking for ads.
///
/// This controller is responsible for:
/// - Tracking ad events (impressions, clicks, completions)
/// - Calculating key metrics (CTR, fill rate, etc.)
/// - Reporting ad performance data
class AdAnalyticsController extends GetxController {
  final AnalyticsService _analytics;

  // Key metrics
  final RxDouble fillRate = 0.0.obs;
  final RxDouble showRate = 0.0.obs;
  final RxMap<AdType, double> typeEcpm = <AdType, double>{}.obs;
  final RxMap<AdType, int> loadAttempts =
      <AdType, int>{
        AdType.banner: 0,
        AdType.native: 0,
        AdType.interstitial: 0,
        AdType.rewarded: 0,
        AdType.appOpen: 0,
      }.obs;
  final RxMap<AdType, int> loadSuccesses =
      <AdType, int>{
        AdType.banner: 0,
        AdType.native: 0,
        AdType.interstitial: 0,
        AdType.rewarded: 0,
        AdType.appOpen: 0,
      }.obs;
  final RxMap<AdType, int> impressions =
      <AdType, int>{
        AdType.banner: 0,
        AdType.native: 0,
        AdType.interstitial: 0,
        AdType.rewarded: 0,
        AdType.appOpen: 0,
      }.obs;
  final RxMap<AdType, int> clicks =
      <AdType, int>{
        AdType.banner: 0,
        AdType.native: 0,
        AdType.interstitial: 0,
        AdType.rewarded: 0,
        AdType.appOpen: 0,
      }.obs;

  // Constructor
  AdAnalyticsController({required AnalyticsService analytics})
    : _analytics = analytics;

  @override
  void onInit() {
    super.onInit();
    // Initialize with default values or load from storage
    _initializeMetrics();
  }

  /// Initialize metrics with default values or from storage
  void _initializeMetrics() {
    for (final type in AdType.values) {
      if (type == AdType.none) continue;

      typeEcpm[type] =
          type == AdType.rewarded
              ? 10.0 // Default eCPM for rewarded ads
              : type == AdType.interstitial
              ? 5.0 // Default eCPM for interstitials
              : 1.0; // Default for other ad types
    }

    _calculateDerivedMetrics();
  }

  /// Track an ad event
  void trackAdEvent(AdEvent event) {
    final adType = event.adType;
    if (adType == AdType.none) return;

    // Update internal metrics
    switch (event.eventType) {
      case AdEventType.requested:
        loadAttempts[adType] = (loadAttempts[adType] ?? 0) + 1;
        break;

      case AdEventType.loaded:
        loadSuccesses[adType] = (loadSuccesses[adType] ?? 0) + 1;
        break;

      case AdEventType.impression:
        impressions[adType] = (impressions[adType] ?? 0) + 1;
        break;

      case AdEventType.clicked:
        clicks[adType] = (clicks[adType] ?? 0) + 1;
        break;

      default:
        // Other event types don't affect these specific metrics
        break;
    }

    // Send to analytics service
    _analytics.trackAdEvent(event);

    // Recalculate derived metrics
    _calculateDerivedMetrics();
  }

  /// Get click-through rate for a specific ad type
  double getCtrForType(AdType type) {
    final typeImpressions = impressions[type] ?? 0;
    final typeClicks = clicks[type] ?? 0;

    if (typeImpressions == 0) return 0;
    return typeClicks / typeImpressions;
  }

  /// Get overall click-through rate
  double getOverallCtr() {
    final totalImpressions = impressions.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final totalClicks = clicks.values.fold(0, (sum, count) => sum + count);

    if (totalImpressions == 0) return 0;
    return totalClicks / totalImpressions;
  }

  /// Calculate fill rate, show rate and other derived metrics
  void _calculateDerivedMetrics() {
    // Calculate fill rate (loads / attempts)
    final totalAttempts = loadAttempts.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final totalSuccesses = loadSuccesses.values.fold(
      0,
      (sum, count) => sum + count,
    );

    if (totalAttempts > 0) {
      fillRate.value = totalSuccesses / totalAttempts;
    }

    // Calculate show rate (impressions / loads)
    final totalImpressions = impressions.values.fold(
      0,
      (sum, count) => sum + count,
    );

    if (totalSuccesses > 0) {
      showRate.value = totalImpressions / totalSuccesses;
    }
  }

  /// Update eCPM value for an ad type
  void updateEcpm(AdType type, double newEcpm) {
    if (type == AdType.none) return;
    typeEcpm[type] = newEcpm;
  }

  /// Get estimated revenue based on impressions and eCPM
  double getEstimatedRevenue() {
    double total = 0;

    for (final type in AdType.values) {
      if (type == AdType.none) continue;

      final typeImpressions = impressions[type] ?? 0;
      final ecpm = typeEcpm[type] ?? 0;

      // Revenue = impressions × (eCPM / 1000)
      total += typeImpressions * (ecpm / 1000);
    }

    return total;
  }

  /// Reset session metrics
  void resetSessionMetrics() {
    // Keep historical data, but reset session-specific counters
    for (final type in AdType.values) {
      if (type == AdType.none) continue;
      loadAttempts[type] = 0;
      loadSuccesses[type] = 0;
      impressions[type] = 0;
      clicks[type] = 0;
    }

    _calculateDerivedMetrics();
  }

  /// Get total impressions across all ad types
  int getImpressions() {
    return impressions.values.fold(0, (sum, count) => sum + count);
  }

  /// Get total clicks across all ad types
  int getClicks() {
    return clicks.values.fold(0, (sum, count) => sum + count);
  }

  /// Get current fill rate value
  double getFillRate() {
    return fillRate.value;
  }

  /// Get current show rate value
  double getShowRate() {
    return showRate.value;
  }
}
