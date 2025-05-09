import 'package:get/get.dart';

import '../models/ad_event.dart';
import '../models/ad_types.dart';
import '../models/user_segment.dart';
import '../services/analytics_service.dart';
import 'ad_analytics_controller.dart';
import 'ad_frequency_controller.dart';
import 'ad_segmentation_controller.dart';

/// Controller responsible for making high-level decisions about ad display.
///
/// This controller acts as a coordinator between specialized controllers:
/// - Delegates frequency control to AdFrequencyController
/// - Delegates user segmentation to AdSegmentationController
/// - Delegates analytics tracking to AdAnalyticsController
///
/// It makes final decisions on which ads to show and when based on input
/// from these specialized controllers.
class AdController extends GetxController {
  // Sub-controllers
  final AdFrequencyController _frequencyController =
      Get.find<AdFrequencyController>();
  final AdSegmentationController _segmentationController =
      Get.find<AdSegmentationController>();
  final AdAnalyticsController _analyticsController =
      Get.find<AdAnalyticsController>();

  // We'll use the analytics controller instead of the direct analytics service

  // Impression counters have been moved to AdAnalyticsController
  // We'll delegate to that controller instead of tracking directly here

  // Historical eCPM data to optimize ad selection
  final RxMap<AdType, double> ecpmData =
      {
        AdType.banner: 0.3,
        AdType.native: 0.8,
        AdType.interstitial: 1.5,
        AdType.rewarded: 2.5,
        AdType.appOpen: 1.0,
      }.obs;

  // A/B test group for the current user
  final RxString abTestGroup = 'A'.obs;

  // Flags to control the ad behavior
  final RxBool isPremiumUser = false.obs;
  final RxBool isAdFreeSession = false.obs;

  // Session configuration
  final RxInt maxInterstitialPerSession = 3.obs;
  final RxInt maxRewardedPerSession = 5.obs;
  final RxInt minSecondsBetweenInterstitials = 120.obs; // 2 minutes

  @override
  void onInit() {
    super.onInit();
    _loadAdSettings();
  }

  /// Determines the best ad type to show based on user segment and historical performance
  AdType getBestAdTypeForUser() {
    // Get current segment from the segmentation controller
    final segment = _segmentationController.currentSegment.value;

    // Premium users see no ads or only non-intrusive ones
    if (isPremiumUser.value) {
      return AdType.none;
    }

    // A/B testing different strategies
    if (abTestGroup.value == 'A') {
      // Strategy A: Value-based segmentation
      switch (segment) {
        case UserSegment.highValue:
          return AdType.rewarded; // Prefer rewarded for high-value users
        case UserSegment.newbie:
          return AdType.interstitial; // Introduce new users to higher eCPM ads
        case UserSegment.premium:
          return AdType.none; // No ads for premium
        default:
          return AdType.native; // Native ads for normal users
      }
    } else {
      // Strategy B: eCPM optimization approach
      // Find the highest eCPM ad type that's eligible to be shown
      var highestEcpm = 0.0;
      var bestType = AdType.native;

      ecpmData.forEach((type, ecpm) {
        if (ecpm > highestEcpm && canShowAd(type)) {
          highestEcpm = ecpm;
          bestType = type;
        }
      });

      return bestType;
    }
  }

  /// Records an ad impression and sends analytics
  void onAdShown(AdType type) {
    if (type == AdType.none) return;

    // Delegate to frequency controller
    _frequencyController.incrementAdCount(type);

    // Delegate to analytics controller
    _analyticsController.trackAdEvent(
      AdEvent.impression(
        type,
        adUnitId: 'unknown', // This would be provided in a real implementation
        userSegment: _segmentationController.currentSegment.value,
      ),
    );

    // Re-evaluate user segment
    _segmentationController.evaluateSegmentChange();
  }

  /// Checks if an ad can be shown based on frequency caps and other rules
  bool canShowAd(AdType type) {
    // Premium users don't see ads
    if (isPremiumUser.value) return false;

    // Ad-free session (e.g. after purchase)
    if (isAdFreeSession.value) return false;

    // Delegate to the appropriate controllers based on ad type
    switch (type) {
      case AdType.interstitial:
        return _frequencyController.canShowInterstitial() &&
            _segmentationController.shouldShowInterstitial();

      case AdType.native:
        return _frequencyController.canShowNativeAd() &&
            _segmentationController.shouldShowNativeAd();

      case AdType.banner:
        return _segmentationController.shouldShowBannerAd();

      case AdType.rewarded:
        return _frequencyController.canShowRewardedAd();

      case AdType.appOpen:
        // Add app open ad logic here
        return true;

      case AdType.none:
        return false;

      default:
        return false;
    }
  }

  /// Records ad click for analytics
  void onAdClicked(AdType type) {
    if (type == AdType.none) return;

    // Delegate to analytics controller
    _analyticsController.trackAdEvent(
      AdEvent.clicked(
        type,
        adUnitId: 'unknown', // This would be provided in a real implementation
        userSegment: _segmentationController.currentSegment.value,
      ),
    );
  }

  /// Records when a user receives a reward from a rewarded ad
  void onRewardEarned(String rewardType, int amount) {
    // Delegate to analytics controller
    _analyticsController.trackAdEvent(
      AdEvent.rewarded(
        AdType.rewarded,
        adUnitId: 'unknown', // This would be provided in a real implementation
        rewardAmount: amount,
        rewardType: rewardType,
        userSegment: _segmentationController.currentSegment.value,
      ),
    );
  }

  /// Updates eCPM data from ad network reports (should be called periodically)
  void updateEcpmData(Map<AdType, double> newData) {
    ecpmData.value = {...ecpmData, ...newData};
  }

  /// Marks the current session as ad-free (e.g., after a purchase)
  void setAdFreeSession(bool isAdFree) {
    isAdFreeSession.value = isAdFree;
  }

  /// Updates the user's premium status
  void setPremiumUser(bool isPremium) {
    isPremiumUser.value = isPremium;
  }

  /// Updates the user's A/B test group
  void setAbTestGroup(String group) {
    abTestGroup.value = group;
  }

  /// Loads ad settings from configuration
  void _loadAdSettings() {
    // This would typically load from remote config or settings
    // For now we'll use default values already set
  }

  /// Resets session-specific counters
  void resetSessionData() {
    // Reset session in frequency controller
    _frequencyController.resetSessionCounts();

    // Reset session in analytics controller
    _analyticsController.resetSessionMetrics();

    // Reset local flags
    isAdFreeSession.value = false;
  }
}
