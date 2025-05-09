import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controllers/ad_analytics_controller.dart';
import '../models/ad_event.dart';
import '../models/ad_types.dart';
import '../models/user_segment.dart';
import '../services/ad_id_provider.dart';

/// Manager for rewarded ads.
///
/// This class handles:
/// - Loading rewarded ads
/// - Pre-caching for faster display
/// - Showing rewarded ads with proper callbacks
/// - Handling reward callbacks
/// - Tracking rewarded ad performance
class RewardedManager extends GetxController {
  final AdAnalyticsController _analytics;

  // Cache of loaded rewarded ads
  final _loadedRewardedAds = <String, RewardedAd>{};

  // Loading state
  final _isLoading = <String, bool>{}.obs;

  // Whether ads are being shown
  final _isShowingAd = false.obs;

  /// Constructor
  RewardedManager({required AdAnalyticsController analytics})
      : _analytics = analytics;

  @override
  void onClose() {
    // Dispose all loaded rewarded ads
    for (final rewardedAd in _loadedRewardedAds.values) {
      rewardedAd.dispose();
    }
    _loadedRewardedAds.clear();
    super.onClose();
  }

  /// Check if a rewarded ad is currently loading
  bool isAdLoading(String placementName) {
    return _isLoading[placementName] ?? false;
  }

  /// Check if any rewarded ad is currently showing
  bool get isShowingAd => _isShowingAd.value;

  /// Load a rewarded ad
  Future<bool> loadRewarded({
    required String placementName,
    bool useTestAds = !kReleaseMode,
    UserSegment? userSegment,
  }) async {
    // Check if we're already loading this ad
    if (_isLoading[placementName] == true) {
      return false;
    }

    // Check if already loaded
    if (_loadedRewardedAds.containsKey(placementName)) {
      return true;
    }

    // Mark as loading
    _isLoading[placementName] = true;

    // Get ad unit ID
    final adUnitId = placementName.contains('_')
        ? AdIdProvider.getCustomPlacementId(
            placementName: placementName,
            useTestAds: useTestAds,
          )
        : AdIdProvider.getAdUnitId(
            adType: AdType.rewarded,
            useTestAds: useTestAds,
          );

    // Track request event
    _analytics.trackAdEvent(AdEvent.requested(
      AdType.rewarded,
      adUnitId: adUnitId,
      userSegment: userSegment,
      isTestAd: useTestAds,
    ));

    try {
      // Load rewarded ad
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _loadedRewardedAds[placementName] = ad;
            _isLoading[placementName] = false;

            // Track success event
            _analytics.trackAdEvent(AdEvent.loaded(
              AdType.rewarded,
              adUnitId: adUnitId,
              userSegment: userSegment,
              isTestAd: useTestAds,
            ));
          },
          onAdFailedToLoad: (error) {
            _isLoading[placementName] = false;

            // Track failure event
            _analytics.trackAdEvent(AdEvent.failed(
              AdType.rewarded,
              adUnitId: adUnitId,
              error: error.message,
              errorCode: error.code,
              userSegment: userSegment,
              isTestAd: useTestAds,
            ));
          },
        ),
      );

      return true;
    } catch (e) {
      // Handle error
      print('Error loading rewarded ad: $e');
      _isLoading[placementName] = false;
      return false;
    }
  }

  /// Show a loaded rewarded ad
  Future<bool> showRewarded({
    required String placementName,
    bool useTestAds = !kReleaseMode,
    UserSegment? userSegment,
    Function()? onAdShown,
    Function()? onAdDismissed,
    Function(String error)? onAdFailedToShow,
    Function(int amount, String type)? onRewarded,
  }) async {
    // Check if any ad is currently showing
    if (_isShowingAd.value) {
      onAdFailedToShow?.call('Another ad is currently showing');
      return false;
    }

    // Get the loaded rewarded ad
    final rewardedAd = _loadedRewardedAds[placementName];

    // If not loaded, try to load it
    if (rewardedAd == null) {
      if (_isLoading[placementName] != true) {
        final loaded = await loadRewarded(
          placementName: placementName,
          useTestAds: useTestAds,
          userSegment: userSegment,
        );

        if (!loaded) {
          onAdFailedToShow?.call('Failed to load rewarded ad');
          return false;
        }
      }

      // Add a small delay to ensure ad loads
      await Future.delayed(const Duration(milliseconds: 500));

      // Check again after loading
      final justLoadedRewardedAd = _loadedRewardedAds[placementName];
      if (justLoadedRewardedAd == null) {
        onAdFailedToShow?.call('Rewarded ad not available');
        return false;
      }

      // Show the rewarded ad
      try {
        _isShowingAd.value = true;
        onAdShown?.call();

        final adUnitId = placementName.contains('_')
            ? AdIdProvider.getCustomPlacementId(
                placementName: placementName,
                useTestAds: useTestAds,
              )
            : AdIdProvider.getAdUnitId(
                adType: AdType.rewarded,
                useTestAds: useTestAds,
              );

        // Show the ad with callbacks
        justLoadedRewardedAd.show(onUserEarnedReward: (_, reward) {
          _analytics.trackAdEvent(AdEvent.rewarded(
            AdType.rewarded,
            adUnitId: adUnitId,
            rewardAmount: reward.amount.toInt(),
            rewardType: reward.type,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));
          onRewarded?.call(reward.amount.toInt(), reward.type);
        });

        // Track impression
        _analytics.trackAdEvent(AdEvent.impression(
          AdType.rewarded,
          adUnitId: adUnitId,
          userSegment: userSegment,
          isTestAd: useTestAds,
        ));

        // Register full screen callbacks
        justLoadedRewardedAd.fullScreenContentCallback =
            FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _loadedRewardedAds.remove(placementName);
            _isShowingAd.value = false;
            onAdDismissed?.call();

            // Pre-load next ad
            _preloadRewarded(
              placementName: placementName,
              useTestAds: useTestAds,
              userSegment: userSegment,
            );
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _loadedRewardedAds.remove(placementName);
            _isShowingAd.value = false;
            onAdFailedToShow?.call(error.message);
          },
          onAdClicked: (ad) {
            _analytics.trackAdEvent(AdEvent.clicked(
              AdType.rewarded,
              adUnitId: adUnitId,
              userSegment: userSegment,
              isTestAd: useTestAds,
            ));
          },
        );

        return true;
      } catch (e) {
        _isShowingAd.value = false;
        _loadedRewardedAds.remove(placementName);
        onAdFailedToShow?.call('Error showing rewarded ad: $e');
        return false;
      }
    }

    // Show existing rewarded ad
    try {
      _isShowingAd.value = true;
      onAdShown?.call();

      final adUnitId = placementName.contains('_')
          ? AdIdProvider.getCustomPlacementId(
              placementName: placementName,
              useTestAds: useTestAds,
            )
          : AdIdProvider.getAdUnitId(
              adType: AdType.rewarded,
              useTestAds: useTestAds,
            );

      // Show the ad with callbacks
      rewardedAd.show(onUserEarnedReward: (_, reward) {
        _analytics.trackAdEvent(AdEvent.rewarded(
          AdType.rewarded,
          adUnitId: adUnitId,
          rewardAmount: reward.amount.toInt(),
          rewardType: reward.type,
          userSegment: userSegment,
          isTestAd: useTestAds,
        ));
        onRewarded?.call(reward.amount.toInt(), reward.type);
      });

      // Track impression
      _analytics.trackAdEvent(AdEvent.impression(
        AdType.rewarded,
        adUnitId: adUnitId,
        userSegment: userSegment,
        isTestAd: useTestAds,
      ));

      // Register full screen callbacks
      rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadedRewardedAds.remove(placementName);
          _isShowingAd.value = false;
          onAdDismissed?.call();

          // Pre-load next ad
          _preloadRewarded(
            placementName: placementName,
            useTestAds: useTestAds,
            userSegment: userSegment,
          );
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadedRewardedAds.remove(placementName);
          _isShowingAd.value = false;
          onAdFailedToShow?.call(error.message);
        },
        onAdClicked: (ad) {
          _analytics.trackAdEvent(AdEvent.clicked(
            AdType.rewarded,
            adUnitId: adUnitId,
            userSegment: userSegment,
            isTestAd: useTestAds,
          ));
        },
      );

      return true;
    } catch (e) {
      _isShowingAd.value = false;
      _loadedRewardedAds.remove(placementName);
      onAdFailedToShow?.call('Error showing rewarded ad: $e');
      return false;
    }
  }

  /// Pre-load a rewarded ad for faster display later
  Future<void> _preloadRewarded({
    required String placementName,
    bool useTestAds = !kReleaseMode,
    UserSegment? userSegment,
  }) async {
    // Don't reload if already loaded or loading
    if (_loadedRewardedAds.containsKey(placementName) ||
        _isLoading[placementName] == true) {
      return;
    }

    // Load the rewarded ad in the background
    loadRewarded(
      placementName: placementName,
      useTestAds: useTestAds,
      userSegment: userSegment,
    );
  }

  /// Check if a rewarded ad is ready to show
  bool isRewardedReady(String placementName) {
    return _loadedRewardedAds.containsKey(placementName);
  }

  /// Dispose a specific rewarded ad
  void disposeRewarded(String placementName) {
    final rewardedAd = _loadedRewardedAds[placementName];
    if (rewardedAd != null) {
      rewardedAd.dispose();
      _loadedRewardedAds.remove(placementName);
    }
  }
}
