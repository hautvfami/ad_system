import 'package:get/get.dart';

import '../models/user_segment.dart';

/// Controls user segmentation for targeted ad delivery.
///
/// This controller categorizes users into different segments based on their behavior,
/// which helps in delivering personalized ad experiences and optimizing revenue.
class AdSegmentationController extends GetxController {
  // Current user segment
  final Rx<UserSegment> currentSegment = UserSegment.normal.obs;

  // User metrics for segmentation
  final RxInt userAppOpenCount = 0.obs;
  final RxInt userSessionsCount = 0.obs;
  final RxInt userDaysActive = 0.obs;
  final RxDouble userTotalSpent = 0.0.obs;
  final RxInt userCompletedActions = 0.obs;
  final RxBool isPremiumUser = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserMetrics();
  }

  /// Initialize segments based on stored data
  Future<void> initializeSegments() async {
    await loadUserMetrics();
    evaluateUserSegment();
  }

  /// Evaluate if the user needs to be moved to a different segment
  void evaluateSegmentChange() {
    evaluateUserSegment();
  }

  /// Check if interstitials should be shown based on user segment
  bool shouldShowInterstitial() {
    switch (currentSegment.value) {
      case UserSegment newUser when newUser == UserSegment.newbie:
        // Show fewer interstitials for new users
        return userSessionsCount.value > 2; // Only after 2 sessions

      case UserSegment highValue when highValue == UserSegment.highValue:
        // Reduce interstitials for high-value users
        return userSessionsCount.value % 2 == 0; // Show on every other session

      case UserSegment premium when premium == UserSegment.premium:
        // No interstitials for premium users
        return false;

      default:
        // Standard behavior for normal users
        return true;
    }
  }

  /// Check if native ads should be shown based on user segment
  bool shouldShowNativeAd() {
    switch (currentSegment.value) {
      case UserSegment newUser when newUser == UserSegment.newbie:
        // Show fewer native ads for new users
        return userSessionsCount.value > 1; // Only after first session

      case UserSegment premium when premium == UserSegment.premium:
        // No native ads for premium users
        return false;

      default:
        // Standard behavior for other users
        return true;
    }
  }

  /// Check if banner ads should be shown based on user segment
  bool shouldShowBannerAd() {
    switch (currentSegment.value) {
      case UserSegment premium when premium == UserSegment.premium:
        // No banners for premium users
        return false;

      default:
        return true;
    }
  }

  /// Increment session count
  void incrementSessionCount() {
    userSessionsCount.value++;
    _saveUserMetrics();
    evaluateUserSegment();
  }

  /// Update premium status
  void updatePremiumStatus(bool isPremium) {
    isPremiumUser.value = isPremium;
    evaluateUserSegment();
  }

  /// Record a completed action (e.g., completing a lesson, reading an article)
  void recordCompletedAction() {
    userCompletedActions.value++;
    _saveUserMetrics();
    evaluateUserSegment();
  }

  /// Record an in-app purchase
  void recordPurchase(double amount) {
    userTotalSpent.value += amount;
    _saveUserMetrics();
    evaluateUserSegment();
  }

  /// Main segmentation logic
  void evaluateUserSegment() {
    if (isPremiumUser.value) {
      currentSegment.value = UserSegment.premium;
      return;
    }

    if (userTotalSpent.value > 20.0 || userCompletedActions.value > 50) {
      currentSegment.value = UserSegment.highValue;
      return;
    }

    if (userSessionsCount.value < 3) {
      currentSegment.value = UserSegment.newbie;
      return;
    }

    currentSegment.value = UserSegment.normal;
  }

  /// Load user metrics from storage
  Future<void> loadUserMetrics() async {
    // This would normally load from storage, but for now we'll use defaults
    // Implementation depends on your storage mechanism
    userSessionsCount.value = 0;
    userAppOpenCount.value = 0;
    userDaysActive.value = 0;
    userTotalSpent.value = 0.0;
    userCompletedActions.value = 0;
  }

  /// Save user metrics to storage
  Future<void> _saveUserMetrics() async {
    // Implementation depends on your storage mechanism
  }
}
