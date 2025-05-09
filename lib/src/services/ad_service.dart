import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controllers/ad_controller.dart';
import '../models/ad_types.dart';
import 'analytics_service.dart';

/// Service responsible for initializing ad SDKs, loading ads, and managing their lifecycle.
class AdService extends GetxService {
  final AdController _adController = Get.find<AdController>();
  final AnalyticsService _analytics = Get.find<AnalyticsService>();

  // Ad Unit IDs (should be moved to environment config in production)
  final Map<String, String> _adUnitIds = {
    'banner': 'ca-app-pub-3940256099942544/6300978111', // Test ID
    'interstitial': 'ca-app-pub-3940256099942544/1033173712', // Test ID
    'rewarded': 'ca-app-pub-3940256099942544/5224354917', // Test ID
    'native': 'ca-app-pub-3940256099942544/2247696110', // Test ID
    'appOpen': 'ca-app-pub-3940256099942544/3419835294', // Test ID
  };

  // Cache for loaded ads
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;
  AppOpenAd? _appOpenAd;

  // Loading state tracking
  final RxBool bannerAdLoading = false.obs;
  final RxBool interstitialAdLoading = false.obs;
  final RxBool rewardedAdLoading = false.obs;
  final RxBool nativeAdLoading = false.obs;
  final RxBool appOpenAdLoading = false.obs;

  /// Initialize the ad service and SDK
  Future<void> init() async {
    // Initialize the Google Mobile Ads SDK
    await MobileAds.instance.initialize();

    // Set test device IDs for development (important to avoid invalid activity)
    // MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(testDeviceIds: ['TEST_DEVICE_ID']),
    // );

    // Pre-load initial ads
    await _preloadInitialAds();
  }

  /// Pre-loads the initial set of ads when the app starts
  Future<void> _preloadInitialAds() async {
    // Load app open ad first as it's likely needed soonest
    loadAppOpenAd();

    // Load other ad types with slight delays to avoid overwhelming the SDK
    await Future.delayed(const Duration(milliseconds: 500));
    loadBannerAd();

    await Future.delayed(const Duration(milliseconds: 500));
    loadInterstitialAd();
  }

  /// Loads a banner ad
  Future<void> loadBannerAd() async {
    if (bannerAdLoading.value || _bannerAd != null) return;

    bannerAdLoading.value = true;

    BannerAd(
      adUnitId: _adUnitIds['banner']!,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerAd = ad as BannerAd;
          bannerAdLoading.value = false;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          bannerAdLoading.value = false;
          _analytics.trackAdFailedToLoad(AdType.banner, error.message);

          // Retry after a delay
          Future.delayed(const Duration(seconds: 60), loadBannerAd);
        },
        onAdClicked: (ad) {
          _adController.onAdClicked(AdType.banner);
        },
        onAdImpression: (ad) {
          _adController.onAdShown(AdType.banner);
        },
      ),
    ).load();
  }

  /// Loads an interstitial ad
  Future<void> loadInterstitialAd() async {
    if (interstitialAdLoading.value || _interstitialAd != null) return;

    interstitialAdLoading.value = true;

    InterstitialAd.load(
      adUnitId: _adUnitIds['interstitial']!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          interstitialAdLoading.value = false;

          // Set up callback for when ad is closed
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _disposeInterstitialAd();
              _analytics.trackAdClosed(AdType.interstitial);

              // Preload next interstitial
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _disposeInterstitialAd();
              _analytics.trackAdFailedToLoad(
                  AdType.interstitial, error.message);

              // Retry after a delay
              Future.delayed(const Duration(seconds: 30), loadInterstitialAd);
            },
            onAdImpression: (ad) {
              _adController.onAdShown(AdType.interstitial);
            },
            onAdClicked: (ad) {
              _adController.onAdClicked(AdType.interstitial);
            },
          );
        },
        onAdFailedToLoad: (error) {
          interstitialAdLoading.value = false;
          _analytics.trackAdFailedToLoad(AdType.interstitial, error.message);

          // Retry after a delay
          Future.delayed(const Duration(seconds: 30), loadInterstitialAd);
        },
      ),
    );
  }

  /// Loads a rewarded ad
  Future<void> loadRewardedAd() async {
    if (rewardedAdLoading.value || _rewardedAd != null) return;

    rewardedAdLoading.value = true;

    RewardedAd.load(
      adUnitId: _adUnitIds['rewarded']!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          rewardedAdLoading.value = false;

          // Set up callback for when ad is closed
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _disposeRewardedAd();
              _analytics.trackAdClosed(AdType.rewarded);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _disposeRewardedAd();
              _analytics.trackAdFailedToLoad(AdType.rewarded, error.message);

              // Retry after a delay
              Future.delayed(const Duration(seconds: 30), loadRewardedAd);
            },
            onAdImpression: (ad) {
              _adController.onAdShown(AdType.rewarded);
            },
            onAdClicked: (ad) {
              _adController.onAdClicked(AdType.rewarded);
            },
          );
        },
        onAdFailedToLoad: (error) {
          rewardedAdLoading.value = false;
          _analytics.trackAdFailedToLoad(AdType.rewarded, error.message);

          // Retry after a delay
          Future.delayed(const Duration(seconds: 30), loadRewardedAd);
        },
      ),
    );
  }

  /// Loads a native ad
  Future<void> loadNativeAd() async {
    if (nativeAdLoading.value || _nativeAd != null) return;

    nativeAdLoading.value = true;

    NativeAd(
      adUnitId: _adUnitIds['native']!,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeAd = ad as NativeAd;
          nativeAdLoading.value = false;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          nativeAdLoading.value = false;
          _analytics.trackAdFailedToLoad(AdType.native, error.message);

          // Retry after a delay
          Future.delayed(const Duration(seconds: 60), loadNativeAd);
        },
        onAdClicked: (ad) {
          _adController.onAdClicked(AdType.native);
        },
        onAdImpression: (ad) {
          _adController.onAdShown(AdType.native);
        },
      ),
      // Specify desired native ad template
      factoryId: 'listTile',
    ).load();
  }

  /// Loads an app open ad
  Future<void> loadAppOpenAd() async {
    if (appOpenAdLoading.value || _appOpenAd != null) return;

    appOpenAdLoading.value = true;

    AppOpenAd.load(
      adUnitId: _adUnitIds['appOpen']!,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          appOpenAdLoading.value = false;

          // Set up callback for when ad is closed
          _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _disposeAppOpenAd();
              _analytics.trackAdClosed(AdType.appOpen);

              // Preload next app open ad
              loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _disposeAppOpenAd();
              _analytics.trackAdFailedToLoad(AdType.appOpen, error.message);

              // Retry after a delay
              Future.delayed(const Duration(seconds: 30), loadAppOpenAd);
            },
            onAdImpression: (ad) {
              _adController.onAdShown(AdType.appOpen);
            },
            onAdClicked: (ad) {
              _adController.onAdClicked(AdType.appOpen);
            },
          );
        },
        onAdFailedToLoad: (error) {
          appOpenAdLoading.value = false;
          _analytics.trackAdFailedToLoad(AdType.appOpen, error.message);

          // Retry after a delay
          Future.delayed(const Duration(seconds: 30), loadAppOpenAd);
        },
      ),
      // orientation: AppOpenAd.orientationPortrait,
    );
  }

  /// Shows a banner ad if available
  Widget? getBannerAdWidget() {
    if (_bannerAd == null) {
      // Load if not already loading
      if (!bannerAdLoading.value) {
        loadBannerAd();
      }
      return null;
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Shows an interstitial ad if available and allowed
  Future<bool> showInterstitialAd() async {
    if (_adController.canShowAd(AdType.interstitial) &&
        _interstitialAd != null) {
      try {
        await _interstitialAd!.show();
        return true;
      } catch (e) {
        _analytics.trackAdFailedToLoad(AdType.interstitial, e.toString());
        _disposeInterstitialAd();
        loadInterstitialAd();
        return false;
      }
    } else {
      // Load if not already loading
      if (!interstitialAdLoading.value && _interstitialAd == null) {
        loadInterstitialAd();
      }
      return false;
    }
  }

  /// Shows a rewarded ad if available and returns whether it was shown
  Future<bool> showRewardedAd({
    required Function(String type, int amount) onRewarded,
  }) async {
    if (_adController.canShowAd(AdType.rewarded) && _rewardedAd != null) {
      try {
        await _rewardedAd!.show(onUserEarnedReward: (_, reward) {
          _adController.onRewardEarned(reward.type, reward.amount.toInt());
          onRewarded(reward.type, reward.amount.toInt());
        });
        return true;
      } catch (e) {
        _analytics.trackAdFailedToLoad(AdType.rewarded, e.toString());
        _disposeRewardedAd();
        loadRewardedAd();
        return false;
      }
    } else {
      // Load if not already loading
      if (!rewardedAdLoading.value && _rewardedAd == null) {
        loadRewardedAd();
      }
      return false;
    }
  }

  /// Returns a built native ad widget if available
  Widget? getNativeAdWidget() {
    if (_nativeAd == null) {
      // Load if not already loading
      if (!nativeAdLoading.value) {
        loadNativeAd();
      }
      return null;
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      child: AdWidget(ad: _nativeAd!),
    );
  }

  /// Shows an app open ad if available and allowed
  Future<bool> showAppOpenAd() async {
    if (_adController.canShowAd(AdType.appOpen) && _appOpenAd != null) {
      try {
        await _appOpenAd!.show();
        return true;
      } catch (e) {
        _analytics.trackAdFailedToLoad(AdType.appOpen, e.toString());
        _disposeAppOpenAd();
        loadAppOpenAd();
        return false;
      }
    } else {
      // Load if not already loading
      if (!appOpenAdLoading.value && _appOpenAd == null) {
        loadAppOpenAd();
      }
      return false;
    }
  }

  /// Disposes of the current interstitial ad
  void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  /// Disposes of the current rewarded ad
  void _disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  /// Disposes of the current app open ad
  void _disposeAppOpenAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }

  /// Disposes of the current native ad
  void _disposeNativeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
  }

  /// Disposes of the current banner ad
  void _disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  /// Disposes all ads when service is destroyed
  @override
  void onClose() {
    _disposeBannerAd();
    _disposeInterstitialAd();
    _disposeRewardedAd();
    _disposeNativeAd();
    _disposeAppOpenAd();
    super.onClose();
  }
}
