import 'package:ad_system/ad_system.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/theme_extractor.dart';
import 'package:flutter/material.dart';

/// Extension on AdsManager providing theme-aware native ad functionality
extension AdsManagerThemeExtensions on AdsManager {
  /// Loads a native ad with theme-aware styling from the current Flutter context
  Future<dynamic> loadThemedNativeAd({
    required BuildContext context,
    required String placementName,
    String template = 'medium',
    Function(dynamic ad)? onAdLoaded,
    Function(String error)? onAdFailedToLoad,
    Map<String, Object>? additionalCustomOptions,
  }) async {
    // Extract theme information
    Map<String, Object> themeOptions = Map<String, Object>.from(
      ThemeExtractor.extractNativeAdTheme(context),
    );

    // Merge with additional custom options if provided
    if (additionalCustomOptions != null) {
      themeOptions.addAll(additionalCustomOptions);
    }

    // Load the ad with theme options
    return loadNativeAd(
      placementName: placementName,
      template: template,
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
      customOptions: themeOptions,
    );
  }

  /// Creates a Container that properly wraps a native ad with appropriate styling
  /// to match the current Flutter theme
  Widget createThemedNativeAdContainer({
    required BuildContext context,
    required dynamic nativeAd,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),
    BorderRadius? borderRadius,
  }) {
    // Use Flutter's theme to style the container
    final theme = Theme.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12.0),
        color: Colors.transparent,
      ),
      padding: padding,
      // Use AdWidget to display the native ad
      child: AdWidget(ad: nativeAd),
    );
  }

  /// Convenience method to load and display a themed native ad
  Future<Widget?> loadAndCreateThemedNativeAd({
    required BuildContext context,
    required String placementName,
    String template = 'medium',
    EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),
    BorderRadius? borderRadius,
    Map<String, Object>? additionalCustomOptions,
  }) async {
    final ad = await loadThemedNativeAd(
      context: context,
      placementName: placementName,
      template: template,
      additionalCustomOptions: additionalCustomOptions,
    );

    if (ad == null) return null;

    return createThemedNativeAdContainer(
      context: context,
      nativeAd: ad,
      padding: padding,
      borderRadius: borderRadius,
    );
  }
}
