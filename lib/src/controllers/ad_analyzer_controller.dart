import 'dart:convert';

import 'package:get/get.dart';

import '../models/ad_types.dart';
import '../models/user_segment.dart';

/// Configuration for the ad analysis engine.
///
/// This class provides settings for analyzing ad performance and implementing
/// adaptive strategies for ad display.
class AdAnalyzerConfig {
  /// Minimum eCPM threshold for showing an ad type
  final Map<AdType, double> minEcpmThresholds;

  /// Number of impressions needed before making optimization decisions
  final int minImpressionThreshold;

  /// Time window for analysis (in hours)
  final int analysisTimeWindowHours;

  /// Whether to use adaptive waterfall (try different networks based on performance)
  final bool useAdaptiveWaterfall;

  /// Whether to use time-of-day optimization
  final bool useTimeOfDayOptimization;

  /// When true, automatically adjusts frequency caps based on user engagement
  final bool useDynamicFrequencyCaps;

  /// Whether to prioritize retention over revenue for new users
  final bool prioritizeRetentionForNewUsers;

  /// Whether to use smart preloading (predict and preload ads before they're needed)
  final bool useSmartPreloading;

  /// How many hours of data to store for analysis
  final int dataRetentionHours;

  /// Prioritization matrix for ad types by segment (higher is more prioritized)
  final Map<UserSegment, Map<AdType, int>> segmentPrioritization;

  const AdAnalyzerConfig({
    required this.minEcpmThresholds,
    this.minImpressionThreshold = 100,
    this.analysisTimeWindowHours = 24,
    this.useAdaptiveWaterfall = true,
    this.useTimeOfDayOptimization = true,
    this.useDynamicFrequencyCaps = true,
    this.prioritizeRetentionForNewUsers = true,
    this.useSmartPreloading = true,
    this.dataRetentionHours = 168, // 7 days
    required this.segmentPrioritization,
  });

  /// Create a default configuration
  factory AdAnalyzerConfig.defaultConfig() {
    return AdAnalyzerConfig(
      minEcpmThresholds: {
        AdType.banner: 0.1,
        AdType.native: 0.3,
        AdType.interstitial: 0.5,
        AdType.rewarded: 1.0,
        AdType.appOpen: 0.5,
      },
      segmentPrioritization: {
        UserSegment.newbie: {
          AdType.banner: 1,
          AdType.native: 2,
          AdType.interstitial: 0, // Lower priority for new users
          AdType.rewarded: 3,
          AdType.appOpen: 0, // Lower priority for new users
        },
        UserSegment.normal: {
          AdType.banner: 1,
          AdType.native: 2,
          AdType.interstitial: 3,
          AdType.rewarded: 4,
          AdType.appOpen: 2,
        },
        UserSegment.highValue: {
          AdType.banner: 0, // Lower priority for high-value users
          AdType.native: 1,
          AdType.interstitial: 2,
          AdType.rewarded: 5, // Higher priority for rewarded
          AdType.appOpen: 3,
        },
        UserSegment.premium: {
          AdType.banner: 0,
          AdType.native: 0,
          AdType.interstitial: 0,
          AdType.rewarded: 2, // Only rewarded for premium
          AdType.appOpen: 0,
        },
      },
    );
  }

  /// Create a copy with overridden values
  AdAnalyzerConfig copyWith({
    Map<AdType, double>? minEcpmThresholds,
    int? minImpressionThreshold,
    int? analysisTimeWindowHours,
    bool? useAdaptiveWaterfall,
    bool? useTimeOfDayOptimization,
    bool? useDynamicFrequencyCaps,
    bool? prioritizeRetentionForNewUsers,
    bool? useSmartPreloading,
    int? dataRetentionHours,
    Map<UserSegment, Map<AdType, int>>? segmentPrioritization,
  }) {
    return AdAnalyzerConfig(
      minEcpmThresholds: minEcpmThresholds ?? this.minEcpmThresholds,
      minImpressionThreshold:
          minImpressionThreshold ?? this.minImpressionThreshold,
      analysisTimeWindowHours:
          analysisTimeWindowHours ?? this.analysisTimeWindowHours,
      useAdaptiveWaterfall: useAdaptiveWaterfall ?? this.useAdaptiveWaterfall,
      useTimeOfDayOptimization:
          useTimeOfDayOptimization ?? this.useTimeOfDayOptimization,
      useDynamicFrequencyCaps:
          useDynamicFrequencyCaps ?? this.useDynamicFrequencyCaps,
      prioritizeRetentionForNewUsers:
          prioritizeRetentionForNewUsers ?? this.prioritizeRetentionForNewUsers,
      useSmartPreloading: useSmartPreloading ?? this.useSmartPreloading,
      dataRetentionHours: dataRetentionHours ?? this.dataRetentionHours,
      segmentPrioritization:
          segmentPrioritization ?? this.segmentPrioritization,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final segmentPrioritizationJson = <String, Map<String, int>>{};
    for (final entry in segmentPrioritization.entries) {
      final adTypePriorities = <String, int>{};
      for (final typeEntry in entry.value.entries) {
        adTypePriorities[typeEntry.key.toString().split('.').last] =
            typeEntry.value;
      }
      segmentPrioritizationJson[entry.key.toString().split('.').last] =
          adTypePriorities;
    }

    final minEcpmThresholdsJson = <String, double>{};
    for (final entry in minEcpmThresholds.entries) {
      minEcpmThresholdsJson[entry.key.toString().split('.').last] = entry.value;
    }

    return {
      'minEcpmThresholds': minEcpmThresholdsJson,
      'minImpressionThreshold': minImpressionThreshold,
      'analysisTimeWindowHours': analysisTimeWindowHours,
      'useAdaptiveWaterfall': useAdaptiveWaterfall,
      'useTimeOfDayOptimization': useTimeOfDayOptimization,
      'useDynamicFrequencyCaps': useDynamicFrequencyCaps,
      'prioritizeRetentionForNewUsers': prioritizeRetentionForNewUsers,
      'useSmartPreloading': useSmartPreloading,
      'dataRetentionHours': dataRetentionHours,
      'segmentPrioritization': segmentPrioritizationJson,
    };
  }

  /// Create from JSON
  factory AdAnalyzerConfig.fromJson(Map<String, dynamic> json) {
    // Parse minEcpmThresholds
    final minEcpmThresholds = <AdType, double>{};
    final thresholds = json['minEcpmThresholds'] as Map<String, dynamic>? ?? {};
    for (final entry in thresholds.entries) {
      final adType = _stringToAdType(entry.key);
      if (adType != AdType.none) {
        minEcpmThresholds[adType] = entry.value as double;
      }
    }

    // Parse segmentPrioritization
    final segmentPrioritization = <UserSegment, Map<AdType, int>>{};
    final segmentPriorities =
        json['segmentPrioritization'] as Map<String, dynamic>? ?? {};
    for (final segmentEntry in segmentPriorities.entries) {
      final segment = _stringToUserSegment(segmentEntry.key);
      if (segment != null && segmentEntry.value is Map) {
        final adTypePriorities = <AdType, int>{};
        for (final typeEntry in (segmentEntry.value as Map).entries) {
          final adType = _stringToAdType(typeEntry.key.toString());
          if (adType != AdType.none) {
            adTypePriorities[adType] = typeEntry.value as int;
          }
        }
        segmentPrioritization[segment] = adTypePriorities;
      }
    }

    return AdAnalyzerConfig(
      minEcpmThresholds: minEcpmThresholds,
      minImpressionThreshold: json['minImpressionThreshold'] as int? ?? 100,
      analysisTimeWindowHours: json['analysisTimeWindowHours'] as int? ?? 24,
      useAdaptiveWaterfall: json['useAdaptiveWaterfall'] as bool? ?? true,
      useTimeOfDayOptimization:
          json['useTimeOfDayOptimization'] as bool? ?? true,
      useDynamicFrequencyCaps: json['useDynamicFrequencyCaps'] as bool? ?? true,
      prioritizeRetentionForNewUsers:
          json['prioritizeRetentionForNewUsers'] as bool? ?? true,
      useSmartPreloading: json['useSmartPreloading'] as bool? ?? true,
      dataRetentionHours: json['dataRetentionHours'] as int? ?? 168,
      segmentPrioritization: segmentPrioritization,
    );
  }

  /// Helper to convert string to AdType
  static AdType _stringToAdType(String value) {
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
  static UserSegment? _stringToUserSegment(String value) {
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
}

/// Ad analyzer that suggests optimal ad configurations based on performance data
class AdAnalyzer extends GetxController {
  // Configuration
  final Rx<AdAnalyzerConfig> config;

  // Analytics data from the last analysis window
  final RxMap<AdType, Map<String, dynamic>> adPerformance =
      <AdType, Map<String, dynamic>>{}.obs;

  // Performance trends (% change compared to previous period)
  final RxMap<AdType, double> revenueChangeTrend = <AdType, double>{}.obs;

  // Recommended maximum frequency caps by segment and type
  final RxMap<UserSegment, Map<AdType, int>> recommendedFrequencyCaps =
      <UserSegment, Map<AdType, int>>{}.obs;

  // Best performing hours of day for each ad type
  final RxMap<AdType, List<int>> bestPerformingHours =
      <AdType, List<int>>{}.obs;

  // When was the last analysis performed
  final Rx<DateTime?> lastAnalysisTime = Rx<DateTime?>(null);

  AdAnalyzer({AdAnalyzerConfig? initialConfig})
      : config = Rx<AdAnalyzerConfig>(
            initialConfig ?? AdAnalyzerConfig.defaultConfig());

  @override
  void onInit() {
    super.onInit();
    _initializeAnalytics();
  }

  /// Initialize analytics with default values
  void _initializeAnalytics() {
    for (final type in AdType.values) {
      if (type == AdType.none) continue;

      adPerformance[type] = {
        'impressions': 0,
        'clicks': 0,
        'ctr': 0.0,
        'ecpm': type == AdType.rewarded
            ? 10.0 // Default eCPM for rewarded ads
            : type == AdType.interstitial
                ? 5.0 // Default eCPM for interstitials
                : 1.0, // Default for other ad types
        'estimatedRevenue': 0.0,
      };

      revenueChangeTrend[type] = 0.0;

      // Default best hours (just for initialization)
      bestPerformingHours[type] = [9, 10, 11, 19, 20, 21, 22];
    }

    // Initialize recommended frequency caps
    for (final segment in UserSegment.values) {
      final adTypeCaps = <AdType, int>{};
      for (final type in AdType.values) {
        if (type == AdType.none) continue;

        // Default frequency caps by segment
        switch (segment) {
          case UserSegment.newbie:
            adTypeCaps[type] = type == AdType.interstitial
                ? 2 // Lower for new users
                : type == AdType.rewarded
                    ? 10 // Higher for rewarded
                    : 5;
            break;
          case UserSegment.normal:
            adTypeCaps[type] = type == AdType.interstitial
                ? 5
                : type == AdType.rewarded
                    ? 15
                    : 10;
            break;
          case UserSegment.highValue:
            adTypeCaps[type] = type == AdType.interstitial
                ? 3 // Lower for high-value users
                : type == AdType.rewarded
                    ? 20 // Higher for rewarded
                    : 7;
            break;
          case UserSegment.premium:
            adTypeCaps[type] = type == AdType.rewarded
                ? 10 // Only rewarded for premium
                : 0;
            break;
        }
      }
      recommendedFrequencyCaps[segment] = adTypeCaps;
    }
  }

  /// Update analytics data with new performance metrics
  void updateAnalytics(Map<AdType, Map<String, dynamic>> newPerformanceData) {
    adPerformance.value = {...adPerformance, ...newPerformanceData};
    _analyze();
  }

  /// Update config from remote source
  void updateConfig(AdAnalyzerConfig newConfig) {
    config.value = newConfig;
    _analyze();
  }

  /// Run an analysis to optimize ad strategy
  void _analyze() {
    // Record analysis time
    lastAnalysisTime.value = DateTime.now();

    // In a real implementation, this would analyze historic data
    // and user behavior to make recommendations

    // For now, we're just providing a simple example implementation
    _analyzeFrequencyCaps();
    _analyzeBestPerformingHours();
    _analyzeRevenueTrends();
  }

  /// Analyze and recommend frequency caps
  void _analyzeFrequencyCaps() {
    // This would use real data analytics to determine optimal caps
    // For this example, we're just using the defaults
  }

  /// Analyze which hours of the day perform best
  void _analyzeBestPerformingHours() {
    // This would analyze historical data to find patterns
    // For this example, we're just using the defaults
  }

  /// Analyze revenue trends
  void _analyzeRevenueTrends() {
    // This would compare performance over time
    // For this example, we're just setting some demo values
    revenueChangeTrend[AdType.banner] = -2.5; // Slight decline
    revenueChangeTrend[AdType.interstitial] = 4.7; // Growing
    revenueChangeTrend[AdType.rewarded] = 12.3; // Strong growth
    revenueChangeTrend[AdType.native] = 1.2; // Stable/small growth
    revenueChangeTrend[AdType.appOpen] = 8.5; // Good growth
  }

  /// Get overall recommended ad strategy
  Map<String, dynamic> getRecommendedStrategy(UserSegment userSegment) {
    // Prioritize ad types based on current performance and config
    final adPrioritiesForSegment =
        config.value.segmentPrioritization[userSegment] ?? {};

    // Sort ad types by priority, then by performance
    final sortedAdTypes = AdType.values
        .where(
            (type) => type != AdType.none && adPrioritiesForSegment[type] != 0)
        .toList()
      ..sort((a, b) {
        // First sort by segment priority
        final priorityA = adPrioritiesForSegment[a] ?? 0;
        final priorityB = adPrioritiesForSegment[b] ?? 0;
        if (priorityA != priorityB) {
          return priorityB.compareTo(priorityA); // Higher priority first
        }

        // Then sort by revenue trend
        final trendA = revenueChangeTrend[a] ?? 0.0;
        final trendB = revenueChangeTrend[b] ?? 0.0;
        return trendB.compareTo(trendA); // Higher trend first
      });

    // Recommended frequency caps
    final recommendedCaps = recommendedFrequencyCaps[userSegment] ?? {};

    return {
      'recommendedAdTypes':
          sortedAdTypes.map((t) => t.toString().split('.').last).toList(),
      'frequencyCaps': recommendedCaps
          .map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'bestTimeOfDay': bestPerformingHours
          .map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'performanceData': adPerformance
          .map((key, value) => MapEntry(key.toString().split('.').last, value)),
    };
  }

  /// Determine if a specific ad should be shown at this moment
  /// based on time of day optimization
  bool shouldShowAdByTimeOptimization(AdType adType) {
    // Skip if time optimization is disabled
    if (!config.value.useTimeOfDayOptimization) {
      return true;
    }

    final currentHour = DateTime.now().hour;
    final bestHours = bestPerformingHours[adType] ?? [];

    // Show ad if current hour is among the best performing
    return bestHours.contains(currentHour);
  }
}
