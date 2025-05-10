import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_manager.dart';
import '../controllers/ad_controller.dart';
import '../models/ad_types.dart';
import '../utils/theme_extractor.dart';
import 'glass_ad_panel.dart';

/// A widget that displays a native ad with a glass effect and fallback content.
class SmartNativeAd extends StatefulWidget {
  /// Height of the ad container
  final double height;

  /// Whether to use glass effect
  final bool useGlassEffect;

  /// Fallback widget when ad isn't available
  final Widget? fallbackContent;

  /// Loading widget to show while ad is loading
  final Widget? loadingWidget;

  /// Border radius for the container
  final double borderRadius;

  /// Ad placement name for analytics
  final String placementName;

  /// Template size to use (small, medium, large)
  final String template;

  /// Additional custom options to pass to the native ad
  final Map<String, Object>? customOptions;

  /// Whether to use theme-aware styling
  final bool useThemeAwareStyling;

  const SmartNativeAd({
    this.height = 280,
    this.useGlassEffect = true,
    this.fallbackContent,
    this.loadingWidget,
    this.borderRadius = 16,
    this.placementName = 'smart_native_ad',
    this.template = 'medium',
    this.customOptions,
    this.useThemeAwareStyling = true,
    super.key,
  });

  @override
  State<SmartNativeAd> createState() => _SmartNativeAdState();
}

class _SmartNativeAdState extends State<SmartNativeAd> {
  NativeAd? _nativeAd;
  bool _isLoading = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    // We'll load the ad in didChangeDependencies instead
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load the ad in didChangeDependencies to ensure the context is ready
    _loadAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    // Avoid duplicate loads
    if (_isLoading) return;

    final AdController adController = Get.find<AdController>();

    // Only show if allowed by the ad controller
    if (!adController.canShowAd(AdType.native)) {
      setState(() {
        _loadFailed = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    // If we already have an ad, dispose it
    _nativeAd?.dispose();

    // Prepare custom options with theme awareness if enabled
    Map<String, Object>? options = widget.customOptions;
    if (widget.useThemeAwareStyling) {
      try {
        final themeOptions = ThemeExtractor.extractNativeAdTheme(context);
        options = {
          ...Map<String, Object>.from(themeOptions),
          ...(widget.customOptions ?? {}),
        };
      } catch (e) {
        debugPrint('SmartNativeAd: Error applying theme options: $e');
        // If theme extraction fails, just use the original options
        options = widget.customOptions;
      }
    }

    // Make sure we have adUnitId debug info
    options = {
      'adDebugInfo':
          'placement=${widget.placementName}, template=${widget.template}',
      ...(options ?? {}),
    };

    try {
      // Load the native ad using AdsManager
      final ad = await AdsManager.instance.loadNativeAd(
        placementName: widget.placementName,
        template: widget.template,
        customOptions: options,
        context: context, // Explicitly pass context
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _nativeAd = ad as NativeAd;
              _isLoading = false;
            });
            debugPrint(
              'SmartNativeAd: Ad loaded successfully with id: ${(ad as NativeAd).adUnitId}',
            );
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('SmartNativeAd: Failed to load ad: $error');
          if (mounted) {
            setState(() {
              _loadFailed = true;
              _isLoading = false;
            });
          }
        },
      );

      // Handle case where ad is returned directly
      if (ad != null && ad is NativeAd && mounted) {
        setState(() {
          _nativeAd = ad;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If ad is available, show it
    if (_nativeAd != null) {
      return _buildAdContainer(AdWidget(ad: _nativeAd!));
    }

    // If loading, show loading widget
    if (_isLoading) {
      return _buildAdContainer(
        widget.loadingWidget ??
            const Center(child: CircularProgressIndicator()),
      );
    }

    // If ad failed to load and fallback content is provided, show it
    if (_loadFailed && widget.fallbackContent != null) {
      return _buildAdContainer(widget.fallbackContent!);
    }

    // Otherwise, don't take up space
    return const SizedBox.shrink();
  }

  Widget _buildAdContainer(Widget content) {
    final container = Container(
      height: widget.height,
      width: double.infinity,
      decoration:
          widget.useGlassEffect
              ? null
              : BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: content,
      ),
    );

    // Apply glass effect if enabled
    if (widget.useGlassEffect) {
      return GlassAdPanel(borderRadius: widget.borderRadius, child: container);
    }

    return container;
  }
}
