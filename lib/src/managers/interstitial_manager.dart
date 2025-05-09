import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controllers/ad_analytics_controller.dart';
import '../models/ad_event.dart';
import '../models/ad_types.dart';
import '../models/user_segment.dart';
import '../services/ad_id_provider.dart';

/// Manager for interstitial ads.
///
/// This class handles:
/// - Loading interstitial ads
/// - Pre-caching for faster display
/// - Showing interstitials with proper callbacks
/// - Tracking interstitial performance
class InterstitialManager extends GetxController {
  final AdAnalyticsController _analytics;

  // Cache of loaded interstitial ads
  final _loadedInterstitials = <String, InterstitialAd>{};

  // Loading state
  final _isLoading = <String, bool>{}.obs;

  // Whether ads are being shown
  final _isShowingAd = false.obs;

  /// Constructor
  InterstitialManager({required AdAnalyticsController analytics})
    : _analytics = analytics;

  @override
  void onClose() {
    // Dispose all loaded interstitials
    for (final interstitial in _loadedInterstitials.values) {
      interstitial.dispose();
    }
    _loadedInterstitials.clear();
    super.onClose();
  }

  /// Check if an interstitial ad is currently loading
  bool isAdLoading(String placementName) {
    return _isLoading[placementName] ?? false;
  }

  /// Check if any interstitial is currently showing
  bool get isShowingAd => _isShowingAd.value;

  /// Check if any interstitial ad is loaded and ready to show
  bool get isAdLoaded => _loadedInterstitials.isNotEmpty;

  /// Load an interstitial ad
  Future<bool> loadInterstitial({
    required String placementName,
    bool useTestAds = !kReleaseMode,
    UserSegment? userSegment,
  }) async {
    // Check if we're already loading this ad
    if (_isLoading[placementName] == true) {
      return false;
    }

    // Check if already loaded
    if (_loadedInterstitials.containsKey(placementName)) {
      return true;
    }

    // Mark as loading
    _isLoading[placementName] = true;

    // Get ad unit ID
    final adUnitId =
        placementName.contains('_')
            ? AdIdProvider.getCustomPlacementId(
              placementName: placementName,
              useTestAds: useTestAds,
            )
            : AdIdProvider.getAdUnitId(
              adType: AdType.interstitial,
              useTestAds: useTestAds,
            );

    // Track request event
    _analytics.trackAdEvent(
      AdEvent.requested(
        AdType.interstitial,
        adUnitId: adUnitId,
        userSegment: userSegment,
        isTestAd: useTestAds,
      ),
    );

    try {
      // Load interstitial ad
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loadedInterstitials[placementName] = ad;
            _isLoading[placementName] = false;

            // Set ad callbacks
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                _isShowingAd.value = true;

                _analytics.trackAdEvent(
                  AdEvent.impression(
                    AdType.interstitial,
                    adUnitId: adUnitId,
                    userSegment: userSegment,
                    isTestAd: useTestAds,
                  ),
                );
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _loadedInterstitials.remove(placementName);
                _isShowingAd.value = false;

                // Pre-load next ad
                _preloadInterstitial(
                  placementName: placementName,
                  useTestAds: useTestAds,
                  userSegment: userSegment,
                );
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _loadedInterstitials.remove(placementName);
                _isShowingAd.value = false;

                _analytics.trackAdEvent(
                  AdEvent.failed(
                    AdType.interstitial,
                    adUnitId: adUnitId,
                    error: 'Failed to show: ${error.message}',
                    errorCode: error.code,
                    userSegment: userSegment,
                    isTestAd: useTestAds,
                  ),
                );
              },
              onAdClicked: (ad) {
                _analytics.trackAdEvent(
                  AdEvent.clicked(
                    AdType.interstitial,
                    adUnitId: adUnitId,
                    userSegment: userSegment,
                    isTestAd: useTestAds,
                  ),
                );
              },
            );

            // Track success event
            _analytics.trackAdEvent(
              AdEvent.loaded(
                AdType.interstitial,
                adUnitId: adUnitId,
                userSegment: userSegment,
                isTestAd: useTestAds,
              ),
            );
          },
          onAdFailedToLoad: (error) {
            _isLoading[placementName] = false;

            // Track failure event
            _analytics.trackAdEvent(
              AdEvent.failed(
                AdType.interstitial,
                adUnitId: adUnitId,
                error: error.message,
                errorCode: error.code,
                userSegment: userSegment,
                isTestAd: useTestAds,
              ),
            );
          },
        ),
      );

      return true;
    } catch (e) {
      // Handle error
      print('Error loading interstitial ad: $e');
      _isLoading[placementName] = false;
      return false;
    }
  }

  /// Show a loaded interstitial ad
  Future<bool> showInterstitial({
    required String placementName,
    bool useTestAds = !kReleaseMode,
    UserSegment? userSegment,
    Function()? onAdShown,
    Function()? onAdDismissed,
    Function(String error)? onAdFailedToShow,
  }) async {
    // Check if any ad is currently showing
    if (_isShowingAd.value) {
      onAdFailedToShow?.call('Another ad is currently showing');
      return false;
    }

    // Get the loaded interstitial
    final interstitial = _loadedInterstitials[placementName];

    // If not loaded, try to load it
    if (interstitial == null) {
      if (_isLoading[placementName] != true) {
        final loaded = await loadInterstitial(
          placementName: placementName,
          useTestAds: useTestAds,
          userSegment: userSegment,
        );

        if (!loaded) {
          onAdFailedToShow?.call('Failed to load interstitial ad');
          return false;
        }
      }

      // Add a small delay to ensure ad loads
      await Future.delayed(const Duration(milliseconds: 500));

      // Check again after loading
      final justLoadedInterstitial = _loadedInterstitials[placementName];
      if (justLoadedInterstitial == null) {
        onAdFailedToShow?.call('Interstitial ad not available');
        return false;
      }

      // Set callbacks and show
      justLoadedInterstitial
          .fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) {
          _isShowingAd.value = true;
          onAdShown?.call();
        },
        onAdDismissedFullScreenContent: (_) {
          justLoadedInterstitial.dispose();
          _loadedInterstitials.remove(placementName);
          _isShowingAd.value = false;
          onAdDismissed?.call();

          // Pre-load next ad
          _preloadInterstitial(
            placementName: placementName,
            useTestAds: useTestAds,
            userSegment: userSegment,
          );
        },
        onAdFailedToShowFullScreenContent: (_, error) {
          justLoadedInterstitial.dispose();
          _loadedInterstitials.remove(placementName);
          _isShowingAd.value = false;
          onAdFailedToShow?.call(error.message);
        },
      );

      justLoadedInterstitial.show();
      return true;
    }

    // Set callbacks on the existing interstitial
    interstitial.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowingAd.value = true;
        onAdShown?.call();
      },
      onAdDismissedFullScreenContent: (_) {
        interstitial.dispose();
        _loadedInterstitials.remove(placementName);
        _isShowingAd.value = false;
        onAdDismissed?.call();

        // Pre-load next ad
        _preloadInterstitial(
          placementName: placementName,
          useTestAds: useTestAds,
          userSegment: userSegment,
        );
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        interstitial.dispose();
        _loadedInterstitials.remove(placementName);
        _isShowingAd.value = false;
        onAdFailedToShow?.call(error.message);
      },
    );

    // Show the interstitial
    interstitial.show();
    return true;
  }

  /// Pre-load an interstitial for faster display later
  Future<void> _preloadInterstitial({
    required String placementName,
    bool useTestAds = !kReleaseMode,
    UserSegment? userSegment,
  }) async {
    // Don't reload if already loaded or loading
    if (_loadedInterstitials.containsKey(placementName) ||
        _isLoading[placementName] == true) {
      return;
    }

    // Load the interstitial in the background
    loadInterstitial(
      placementName: placementName,
      useTestAds: useTestAds,
      userSegment: userSegment,
    );
  }

  /// Dispose a specific interstitial ad
  void disposeInterstitial(String placementName) {
    final interstitial = _loadedInterstitials[placementName];
    if (interstitial != null) {
      interstitial.dispose();
      _loadedInterstitials.remove(placementName);
    }
  }
}
