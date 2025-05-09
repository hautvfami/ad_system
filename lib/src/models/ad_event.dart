import 'ad_types.dart';
import 'user_segment.dart';
import 'ad_reward.dart';

/// Types of ad events for analytics tracking
enum AdEventType {
  requested, // Ad was requested from network
  loaded, // Ad loaded successfully
  loadFailed, // Ad failed to load
  impression, // Ad was displayed to user
  clicked, // User clicked on the ad
  dismissed, // User dismissed the ad (closed)
  completed, // User completed watching ad (e.g., rewarded)
  rewarded, // User earned a reward from the ad
  leftApplication, // User left app due to ad
}

/// Represents an ad-related event for analytics tracking
class AdEvent {
  /// Type of the event
  final AdEventType eventType;

  /// Type of ad involved in this event
  final AdType adType;

  /// Unique identifier for the ad instance
  final String? adUnitId;

  /// Error message if the event is related to a failure
  final String? error;

  /// Error code if available
  final int? errorCode;

  /// Amount of reward given (for rewarded ads)
  final int? rewardAmount;

  /// Type of reward given (for rewarded ads)
  final String? rewardType;

  /// Combined reward object containing type and amount
  AdReward? get reward => rewardAmount != null && rewardType != null
      ? AdReward(type: rewardType!, amount: rewardAmount!)
      : null;

  /// User segment at the time of this event
  final UserSegment? userSegment;

  /// Timestamp when the event occurred
  final DateTime timestamp;

  /// Whether this was a test ad
  final bool isTestAd;

  /// Whether the user was rewarded
  final bool? wasRewarded;

  /// Time taken to load the ad in milliseconds
  final int? loadTimeMs;

  /// Duration the ad was shown in milliseconds
  final int? durationMs;

  /// Additional data related to the event
  final Map<String, dynamic>? metadata;

  /// Estimated Cost Per Mille (eCPM) for this ad impression
  final double? ecpm;

  /// Creates an ad event
  AdEvent({
    required this.eventType,
    required this.adType,
    this.adUnitId,
    this.error,
    this.errorCode,
    this.rewardAmount,
    this.rewardType,
    this.userSegment,
    DateTime? timestamp,
    this.isTestAd = false,
    this.metadata,
    this.ecpm,
    this.wasRewarded,
    this.loadTimeMs,
    this.durationMs,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create an ad request event
  factory AdEvent.requested(
    AdType adType, {
    required String adUnitId,
    UserSegment? userSegment,
    bool isTestAd = false,
  }) {
    return AdEvent(
      eventType: AdEventType.requested,
      adType: adType,
      adUnitId: adUnitId,
      userSegment: userSegment,
      isTestAd: isTestAd,
    );
  }

  /// Create a successful ad load event
  factory AdEvent.loaded(
    AdType adType, {
    required String adUnitId,
    UserSegment? userSegment,
    bool isTestAd = false,
  }) {
    return AdEvent(
      eventType: AdEventType.loaded,
      adType: adType,
      adUnitId: adUnitId,
      userSegment: userSegment,
      isTestAd: isTestAd,
    );
  }

  /// Create a failed ad load event
  factory AdEvent.failed(
    AdType adType, {
    required String adUnitId,
    required String error,
    int? errorCode,
    UserSegment? userSegment,
    bool isTestAd = false,
  }) {
    return AdEvent(
      eventType: AdEventType.loadFailed,
      adType: adType,
      adUnitId: adUnitId,
      error: error,
      errorCode: errorCode,
      userSegment: userSegment,
      isTestAd: isTestAd,
    );
  }

  /// Create an ad impression event
  factory AdEvent.impression(
    AdType adType, {
    required String adUnitId,
    UserSegment? userSegment,
    bool isTestAd = false,
    Map<String, dynamic>? metadata,
    double? ecpm,
  }) {
    return AdEvent(
      eventType: AdEventType.impression,
      adType: adType,
      adUnitId: adUnitId,
      userSegment: userSegment,
      isTestAd: isTestAd,
      metadata: metadata,
      ecpm: ecpm,
    );
  }

  /// Create an ad click event
  factory AdEvent.clicked(
    AdType adType, {
    required String adUnitId,
    UserSegment? userSegment,
    bool isTestAd = false,
  }) {
    return AdEvent(
      eventType: AdEventType.clicked,
      adType: adType,
      adUnitId: adUnitId,
      userSegment: userSegment,
      isTestAd: isTestAd,
    );
  }

  /// Create a rewarded ad completion event
  factory AdEvent.rewarded(
    AdType adType, {
    required String adUnitId,
    int? rewardAmount,
    String? rewardType,
    AdReward? reward,
    UserSegment? userSegment,
    bool isTestAd = false,
  }) {
    return AdEvent(
      eventType: AdEventType.rewarded,
      adType: adType,
      adUnitId: adUnitId,
      rewardAmount: rewardAmount ?? reward?.amount,
      rewardType: rewardType ?? reward?.type,
      userSegment: userSegment,
      isTestAd: isTestAd,
      wasRewarded: true,
    );
  }

  /// Create an ad closed event
  factory AdEvent.closed(
    AdType adType, {
    String? adUnitId,
    UserSegment? userSegment,
    bool isTestAd = false,
    bool? wasFullyWatched,
    int? durationMs,
  }) {
    return AdEvent(
      eventType: AdEventType.dismissed,
      adType: adType,
      adUnitId: adUnitId,
      userSegment: userSegment,
      isTestAd: isTestAd,
      wasRewarded: wasFullyWatched,
      durationMs: durationMs,
    );
  }

  /// Convert to a map for analytics tracking
  Map<String, dynamic> toMap() {
    return {
      'eventType': eventType.toString(),
      'adType': adType.toString(),
      'adUnitId': adUnitId,
      'error': error,
      'errorCode': errorCode,
      'rewardAmount': rewardAmount,
      'rewardType': rewardType,
      'userSegment': userSegment?.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isTestAd': isTestAd,
      if (ecpm != null) 'ecpm': ecpm,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
