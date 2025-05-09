import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ad_controller.dart';
import '../models/ad_types.dart';
import '../services/ad_service.dart';
import 'glass_ad_panel.dart';

/// A widget that displays a native ad with a glass effect and fallback content.
class SmartNativeAd extends StatelessWidget {
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

  const SmartNativeAd({
    this.height = 280,
    this.useGlassEffect = true,
    this.fallbackContent,
    this.loadingWidget,
    this.borderRadius = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AdService adService = Get.find<AdService>();
    final AdController adController = Get.find<AdController>();

    // Only show if allowed by the ad controller
    if (!adController.canShowAd(AdType.native)) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final adWidget = adService.getNativeAdWidget();

      // If ad is available, show it
      if (adWidget != null) {
        return _buildAdContainer(adWidget);
      }

      // If loading, show loading widget
      if (adService.nativeAdLoading.value) {
        return _buildAdContainer(
          loadingWidget ?? const Center(child: CircularProgressIndicator()),
        );
      }

      // If ad failed to load and fallback content is provided, show it
      if (fallbackContent != null) {
        return _buildAdContainer(fallbackContent!);
      }

      // Otherwise, don't take up space
      return const SizedBox.shrink();
    });
  }

  Widget _buildAdContainer(Widget content) {
    final container = Container(
      height: height,
      width: double.infinity,
      decoration: useGlassEffect
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.grey.shade300),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      ),
    );

    // Apply glass effect if enabled
    if (useGlassEffect) {
      return GlassAdPanel(
        borderRadius: borderRadius,
        child: container,
      );
    }

    return container;
  }
}
