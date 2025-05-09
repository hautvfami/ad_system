import 'dart:math';

import 'package:get/get.dart';

import '../models/ad_event.dart';
import '../models/ad_types.dart';

/// A system for attributing revenue to different parts of the application
/// and tracking which placements and strategies generate the most earnings.
class RevenueAttribution extends GetxController {
  // Total estimated revenue by ad type
  final RxMap<AdType, double> revenueByType = <AdType, double>{}.obs;

  // Revenue by specific placement
  final RxMap<String, double> revenueByPlacement = <String, double>{}.obs;

  // Revenue by screen/route in the app
  final RxMap<String, double> revenueByScreen = <String, double>{}.obs;

  // Revenue by user segment
  final RxMap<String, double> revenueBySegment = <String, double>{}.obs;

  // Revenue by hour of day (24-hour format)
  final List<double> revenueByHour = List.filled(24, 0.0);

  // Revenue by day of week (0 = Sunday, 6 = Saturday)
  final List<double> revenueByDayOfWeek = List.filled(7, 0.0);

  // Cache of most valuable placements
  final RxList<MapEntry<String, double>> _topPlacements =
      <MapEntry<String, double>>[].obs;

  /// Initialize with default values
  @override
  void onInit() {
    super.onInit();

    // Initialize revenue by type
    for (final adType in AdType.values) {
      if (adType != AdType.none) {
        revenueByType[adType] = 0.0;
      }
    }
  }

  /// Track revenue from an ad impression
  void trackImpression({
    required AdType adType,
    required String placementId,
    String? screenName,
    String? userSegment,
    double? ecpm,
  }) {
    // Calculate revenue (estimated) from this impression
    // eCPM means earnings per 1000 impressions
    final effectiveEcpm = ecpm ?? _getDefaultEcpm(adType);
    final estimatedRevenue = effectiveEcpm / 1000.0;

    // Update revenue by type
    revenueByType[adType] = (revenueByType[adType] ?? 0.0) + estimatedRevenue;

    // Update revenue by placement
    revenueByPlacement[placementId] =
        (revenueByPlacement[placementId] ?? 0.0) + estimatedRevenue;

    // Update revenue by screen if provided
    if (screenName != null) {
      revenueByScreen[screenName] =
          (revenueByScreen[screenName] ?? 0.0) + estimatedRevenue;
    }

    // Update revenue by user segment if provided
    if (userSegment != null) {
      revenueBySegment[userSegment] =
          (revenueBySegment[userSegment] ?? 0.0) + estimatedRevenue;
    }

    // Update revenue by time
    final now = DateTime.now();
    revenueByHour[now.hour] += estimatedRevenue;
    revenueByDayOfWeek[now.weekday % 7] += estimatedRevenue;

    // Invalidate cached top placements
    _refreshTopPlacements();
  }

  /// Track revenue from an ad event
  void trackAdEvent(AdEvent event) {
    // Only track impressions for now
    if (event.eventType == AdEventType.impression) {
      trackImpression(
        adType: event.adType,
        placementId: event.adUnitId ?? 'unknown',
        userSegment: event.userSegment?.toString().split('.').last,
        ecpm: event.ecpm,
      );
    }
  }

  /// Get total estimated revenue
  double get totalRevenue {
    return revenueByType.values.fold(0.0, (sum, value) => sum + value);
  }

  /// Get top performing ad placements
  List<MapEntry<String, double>> getTopPlacements({int limit = 5}) {
    return _topPlacements.take(limit).toList();
  }

  /// Get top performing screens
  List<MapEntry<String, double>> getTopScreens({int limit = 5}) {
    final screens = revenueByScreen.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return screens.take(limit).toList();
  }

  /// Get best performing hours of day
  List<int> getBestPerformingHours({int limit = 3}) {
    final hoursList = List<MapEntry<int, double>>.generate(
      24,
      (i) => MapEntry(i, revenueByHour[i]),
    );

    hoursList.sort((a, b) => b.value.compareTo(a.value));
    return hoursList.take(limit).map((entry) => entry.key).toList();
  }

  /// Get best performing days of week
  List<int> getBestPerformingDays({int limit = 3}) {
    final daysList = List<MapEntry<int, double>>.generate(
      7,
      (i) => MapEntry(i, revenueByDayOfWeek[i]),
    );

    daysList.sort((a, b) => b.value.compareTo(a.value));
    return daysList.take(limit).map((entry) => entry.key).toList();
  }

  /// Get revenue summary for reporting
  Map<String, dynamic> getRevenueSummary() {
    return {
      'totalRevenue': totalRevenue.toStringAsFixed(2),
      'revenueByType': Map.fromEntries(revenueByType.entries.map((entry) =>
          MapEntry(entry.key.toString().split('.').last,
              entry.value.toStringAsFixed(2)))),
      'topPlacements': getTopPlacements()
          .map((entry) => {
                'placementId': entry.key,
                'revenue': entry.value.toStringAsFixed(2)
              })
          .toList(),
      'topScreens': getTopScreens()
          .map((entry) =>
              {'screen': entry.key, 'revenue': entry.value.toStringAsFixed(2)})
          .toList(),
      'bestHours': getBestPerformingHours(limit: 5),
      'bestDays': getBestPerformingDays().map((day) {
        final dayName = _getDayName(day);
        return {'day': dayName, 'dayIndex': day};
      }).toList(),
    };
  }

  /// Reset all tracking data
  void resetData() {
    revenueByType.clear();
    revenueByPlacement.clear();
    revenueByScreen.clear();
    revenueBySegment.clear();

    for (int i = 0; i < 24; i++) {
      revenueByHour[i] = 0.0;
    }

    for (int i = 0; i < 7; i++) {
      revenueByDayOfWeek[i] = 0.0;
    }

    // Initialize revenue by type again
    for (final adType in AdType.values) {
      if (adType != AdType.none) {
        revenueByType[adType] = 0.0;
      }
    }

    _topPlacements.clear();
  }

  /// Refresh the cached list of top placements
  void _refreshTopPlacements() {
    final placements = revenueByPlacement.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _topPlacements.value = placements;
  }

  /// Get default eCPM value for an ad type
  double _getDefaultEcpm(AdType adType) {
    switch (adType) {
      case AdType.rewarded:
        return 10.0; // Higher eCPM for rewarded ads
      case AdType.interstitial:
        return 5.0; // Medium eCPM for interstitials
      case AdType.native:
        return 2.5; // Medium-low eCPM for natives
      case AdType.banner:
        return 1.0; // Lower eCPM for banners
      case AdType.appOpen:
        return 3.0; // Medium eCPM for app open ads
      default:
        return 1.0;
    }
  }

  /// Get day name from day index
  String _getDayName(int day) {
    const dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    return dayNames[day % 7];
  }
}

/// A class for cohort analysis to optimize ads for different user groups
class CohortAnalysis extends GetxController {
  // Revenue by cohort and day since first seen
  final RxMap<String, Map<int, double>> cohortRevenue =
      <String, Map<int, double>>{}.obs;

  // Retention rates by cohort and day
  final RxMap<String, Map<int, double>> cohortRetention =
      <String, Map<int, double>>{}.obs;

  // Ad engagement (CTR) by cohort and day
  final RxMap<String, Map<int, double>> cohortEngagement =
      <String, Map<int, double>>{}.obs;

  /// Track user activity for cohort analysis
  void trackUserActivity({
    required String userId,
    required String cohort,
    required int daysSinceFirstSeen,
    required bool isActive,
    double? revenue,
    int? adImpressions,
    int? adClicks,
  }) {
    // Track revenue
    if (revenue != null && revenue > 0) {
      if (!cohortRevenue.containsKey(cohort)) {
        cohortRevenue[cohort] = <int, double>{};
      }

      final cohortDayRevenue = cohortRevenue[cohort]!;
      cohortDayRevenue[daysSinceFirstSeen] =
          (cohortDayRevenue[daysSinceFirstSeen] ?? 0.0) + revenue;
    }

    // Track retention
    if (!cohortRetention.containsKey(cohort)) {
      cohortRetention[cohort] = <int, double>{};
    }

    // We need to have tracked total users to calculate retention,
    // but for this example we'll just increment if active
    if (isActive) {
      final cohortDayRetention = cohortRetention[cohort]!;
      cohortDayRetention[daysSinceFirstSeen] =
          (cohortDayRetention[daysSinceFirstSeen] ?? 0.0) + 1;
    }

    // Track ad engagement
    if (adImpressions != null && adImpressions > 0) {
      if (!cohortEngagement.containsKey(cohort)) {
        cohortEngagement[cohort] = <int, double>{};
      }

      final cohortDayEngagement = cohortEngagement[cohort]!;

      // Calculate CTR (click-through rate)
      final ctr = adClicks != null && adClicks > 0
          ? adClicks / adImpressions.toDouble()
          : 0.0;

      // Average with existing data
      final existingCtr = cohortDayEngagement[daysSinceFirstSeen] ?? 0.0;
      final existingWeight =
          cohortDayEngagement[daysSinceFirstSeen] != null ? 0.7 : 0.0;
      final newWeight = 1.0 - existingWeight;

      cohortDayEngagement[daysSinceFirstSeen] =
          (existingCtr * existingWeight) + (ctr * newWeight);
    }
  }

  /// Get optimal ad strategy for a specific cohort and day
  Map<String, dynamic> getOptimalStrategy(
      String cohort, int daysSinceFirstSeen) {
    // This would use the cohort data to determine the best strategy
    // For now, we'll provide a simplified recommendation

    final avgRevenue = _getAverageRevenue(cohort, daysSinceFirstSeen) ?? 0.0;
    final retention = _getRetention(cohort, daysSinceFirstSeen) ?? 0.0;
    final engagement = _getEngagement(cohort, daysSinceFirstSeen) ?? 0.0;

    // Determine factors for recommendation
    final isHighValue = avgRevenue > 0.1; // $0.10 per day
    final isRetained = retention > 0.3; // 30% retention
    final isEngaged = engagement > 0.05; // 5% CTR

    // Generate recommendation
    final recommendedStrategy = <String, dynamic>{
      'adFrequency': _recommendAdFrequency(isHighValue, isRetained, isEngaged),
      'prioritizeAdTypes':
          _recommendAdTypes(isHighValue, isRetained, isEngaged),
      'shouldPrioritizeRetention': !isRetained,
    };

    return recommendedStrategy;
  }

  /// Get average revenue for a cohort on a specific day
  double? _getAverageRevenue(String cohort, int daysSinceFirstSeen) {
    return cohortRevenue[cohort]?[daysSinceFirstSeen];
  }

  /// Get retention rate for a cohort on a specific day
  double? _getRetention(String cohort, int daysSinceFirstSeen) {
    return cohortRetention[cohort]?[daysSinceFirstSeen];
  }

  /// Get engagement rate for a cohort on a specific day
  double? _getEngagement(String cohort, int daysSinceFirstSeen) {
    return cohortEngagement[cohort]?[daysSinceFirstSeen];
  }

  /// Recommend ad frequency based on user factors
  String _recommendAdFrequency(
      bool isHighValue, bool isRetained, bool isEngaged) {
    if (isHighValue && isRetained && isEngaged) {
      return 'high'; // User is valuable, retained and engaged - can show more ads
    } else if (!isRetained && daysSinceFirstSeen < 7) {
      return 'low'; // New user not yet retained - be cautious with ads
    } else if (isEngaged) {
      return 'medium'; // User engages with ads - show a moderate amount
    } else {
      return 'low'; // Default to low frequency
    }
  }

  /// Recommend ad types based on user factors
  List<String> _recommendAdTypes(
      bool isHighValue, bool isRetained, bool isEngaged) {
    if (isHighValue && isEngaged) {
      // High-value engaged users should see rewarded ads prioritized
      return ['rewarded', 'interstitial', 'native', 'banner'];
    } else if (!isRetained && daysSinceFirstSeen < 3) {
      // Brand new users should see minimal interstitials
      return ['native', 'banner', 'rewarded'];
    } else if (isEngaged) {
      // Engaged users can see more interactive ad formats
      return ['interstitial', 'rewarded', 'native', 'banner'];
    } else {
      // Default prioritization
      return ['native', 'banner', 'rewarded', 'interstitial'];
    }
  }

  /// Get days since first seen
  int get daysSinceFirstSeen {
    // In a real implementation, this would track the user's first seen date
    // For this demo, we'll just return a random value
    return Random().nextInt(30);
  }
}
