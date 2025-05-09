import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/ad_event.dart';
import '../models/ad_reward.dart';
import '../models/ad_types.dart';
import '../models/user_segment.dart';

/// Service for tracking analytics events related to ads.
///
/// This service routes analytics events to Firebase Analytics and other
/// analytics platforms to provide insights about ad performance and user interactions.
class AnalyticsService extends GetxService {
  final FirebaseAnalytics? _firebaseAnalytics;

  // Maximum events to batch before sending
  static const int _maxEventsBatchSize = 10;

  // Batched events that haven't been sent yet
  final List<Map<String, dynamic>> _batchedEvents = [];

  // Basic counters for quick in-memory analytics
  final RxMap<String, int> _eventCounts = <String, int>{}.obs;

  // Whether analytics is enabled
  final RxBool _isEnabled = true.obs;

  /// Constructor
  AnalyticsService({FirebaseAnalytics? firebaseAnalytics})
    : _firebaseAnalytics = firebaseAnalytics;

  /// Enable or disable analytics
  set isEnabled(bool value) => _isEnabled.value = value;

  /// Get if analytics is enabled
  bool get isEnabled => _isEnabled.value;

  /// Initialize the service
  Future<void> initialize() async {
    if (_firebaseAnalytics != null) {
      await _firebaseAnalytics!.setAnalyticsCollectionEnabled(_isEnabled.value);
    }
  }

  /// Track an ad event
  Future<void> trackAdEvent(AdEvent event) async {
    if (!_isEnabled.value) return;

    // Update local counter
    final eventName = _getEventName(event.eventType, event.adType);
    _eventCounts[eventName] = (_eventCounts[eventName] ?? 0) + 1;

    // Prepare event parameters
    final params = <String, dynamic>{
      'ad_type': event.adType.toString().split('.').last,
      'ad_unit_id': event.adUnitId ?? 'unknown',
      'is_test_ad': event.isTestAd,
    };

    // Add optional parameters if available
    if (event.error != null) {
      params['error_message'] = event.error;
    }
    if (event.errorCode != null) {
      params['error_code'] = event.errorCode;
    }
    if (event.userSegment != null) {
      params['user_segment'] = event.userSegment.toString().split('.').last;
    }
    if (event.reward != null) {
      params['reward_type'] = event.reward!.type;
      params['reward_amount'] = event.reward!.amount;
    }
    if (event.wasRewarded != null) {
      params['was_rewarded'] = event.wasRewarded;
    }
    if (event.loadTimeMs != null) {
      params['load_time_ms'] = event.loadTimeMs;
    }
    if (event.durationMs != null) {
      params['duration_ms'] = event.durationMs;
    }
    if (event.ecpm != null) {
      params['ecpm'] = event.ecpm;
    }

    // Add to batch
    _batchedEvents.add({
      'name': eventName,
      'params': params,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Send immediately for important events or if batch is large enough
    final isImportantEvent =
        event.eventType == AdEventType.impression ||
        event.eventType == AdEventType.clicked ||
        event.eventType == AdEventType.rewarded;

    if (isImportantEvent || _batchedEvents.length >= _maxEventsBatchSize) {
      await _sendBatchedEvents();
    }

    // Debug logging
    if (kDebugMode) {
      print('Ad Event: $eventName - $params');
    }
  }

  /// Tracks when an ad is shown to a user
  Future<void> trackAdShown(
    AdType adType,
    UserSegment? userSegment, {
    String? adUnitId,
    bool isTestAd = false,
    double? ecpm,
  }) async {
    await trackAdEvent(
      AdEvent.impression(
        adType,
        adUnitId: adUnitId ?? '',
        userSegment: userSegment,
        isTestAd: isTestAd,
        ecpm: ecpm,
      ),
    );
  }

  /// Tracks when an ad is clicked
  Future<void> trackAdClicked(
    AdType adType,
    UserSegment? userSegment, {
    String? adUnitId,
    bool isTestAd = false,
  }) async {
    await trackAdEvent(
      AdEvent.clicked(
        adType,
        adUnitId: adUnitId ?? '',
        userSegment: userSegment,
        isTestAd: isTestAd,
      ),
    );
  }

  /// Tracks when a user earns a reward from watching a rewarded ad
  Future<void> trackRewardEarned(
    String rewardType,
    int amount,
    UserSegment? userSegment, {
    String? adUnitId,
    bool isTestAd = false,
  }) async {
    await trackAdEvent(
      AdEvent.rewarded(
        AdType.rewarded,
        reward: AdReward(type: rewardType, amount: amount),
        adUnitId: adUnitId ?? '',
        userSegment: userSegment,
        isTestAd: isTestAd,
      ),
    );
  }

  /// Tracks when an ad fails to load
  Future<void> trackAdFailedToLoad(
    AdType adType,
    String errorMessage, {
    int? errorCode,
    String? adUnitId,
    UserSegment? userSegment,
    bool isTestAd = false,
  }) async {
    await trackAdEvent(
      AdEvent.failed(
        adType,
        error: errorMessage,
        errorCode: errorCode,
        adUnitId: adUnitId ?? '',
        userSegment: userSegment,
        isTestAd: isTestAd,
      ),
    );
  }

  /// Tracks when an ad is closed by the user
  Future<void> trackAdClosed(
    AdType adType, {
    bool wasFullyWatched = false,
    int? durationMs,
    String? adUnitId,
    UserSegment? userSegment,
    bool isTestAd = false,
  }) async {
    await trackAdEvent(
      AdEvent.closed(
        adType,
        durationMs: durationMs,
        wasFullyWatched: wasFullyWatched,
        adUnitId: adUnitId,
        userSegment: userSegment,
        isTestAd: isTestAd,
      ),
    );
  }

  /// Send all batched events to Firebase and other analytics platforms
  Future<void> _sendBatchedEvents() async {
    if (_batchedEvents.isEmpty) return;

    // Clone and clear the batch
    final eventsToSend = List<Map<String, Object>>.from(_batchedEvents);
    _batchedEvents.clear();

    // Send each event to Firebase Analytics
    if (_firebaseAnalytics != null) {
      for (final event in eventsToSend) {
        try {
          await _firebaseAnalytics.logEvent(
            name: event['name'].toString(),
            parameters: Map<String, Object>.from(
              event['params'] as Map<String, dynamic>,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error sending event to Firebase: $e');
          }
        }
      }
    }

    // Here you would add integrations with other analytics platforms
    // such as Mixpanel, Amplitude, etc.
  }

  /// Get analytics event name from event type and ad type
  String _getEventName(AdEventType eventType, AdType adType) {
    final adTypeName = adType.toString().split('.').last.toLowerCase();

    switch (eventType) {
      case AdEventType.requested:
        return 'ad_requested_$adTypeName';
      case AdEventType.loaded:
        return 'ad_loaded_$adTypeName';
      case AdEventType.loadFailed:
        return 'ad_failed_$adTypeName';
      case AdEventType.impression:
        return 'ad_impression_$adTypeName';
      case AdEventType.clicked:
        return 'ad_clicked_$adTypeName';
      case AdEventType.dismissed:
        return 'ad_closed_$adTypeName';
      case AdEventType.completed:
        return 'ad_completed_$adTypeName';
      case AdEventType.rewarded:
        return 'ad_rewarded_$adTypeName';
      case AdEventType.leftApplication:
        return 'ad_left_app_$adTypeName';
      default:
        return 'ad_event_$adTypeName';
    }
  }

  /// Get event counts for a specific event type (for internal monitoring)
  int getEventCount(AdEventType eventType, AdType adType) {
    final eventName = _getEventName(eventType, adType);
    return _eventCounts[eventName] ?? 0;
  }

  /// Get all event counts (for internal monitoring)
  Map<String, int> getAllEventCounts() {
    return Map<String, int>.from(_eventCounts);
  }

  /// Reset event counts (for internal monitoring)
  void resetEventCounts() {
    _eventCounts.clear();
  }
}
