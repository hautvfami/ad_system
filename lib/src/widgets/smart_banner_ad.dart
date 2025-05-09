import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ad_controller.dart';
import '../models/ad_types.dart';
import '../services/ad_service.dart';
import 'glass_ad_panel.dart';

/// A widget that displays a banner ad with optional glass effect and fallback content.
class SmartBannerAd extends StatelessWidget {
  /// Whether to use glass effect
  final bool useGlassEffect;

  /// Fallback widget when ad isn't available
  final Widget? fallbackContent;

  /// Loading widget to show while ad is loading
  final Widget? loadingWidget;

  /// Border radius for the container
  final double borderRadius;

  /// Additional padding around the ad
  final EdgeInsets padding;

  const SmartBannerAd({
    this.useGlassEffect = true,
    this.fallbackContent,
    this.loadingWidget,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AdService adService = Get.find<AdService>();
    final AdController adController = Get.find<AdController>();

    // Only show if allowed by the ad controller
    if (!adController.canShowAd(AdType.banner)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Obx(() {
        // Explicitly watch the loading status to make this widget reactive
        final isLoading = adService.bannerAdLoading.value;

        // Get the banner ad widget
        final adWidget = adService.getBannerAdWidget();

        // If ad is available, show it
        if (adWidget != null) {
          return _buildAdContainer(adWidget);
        }

        // If loading, show loading widget
        if (isLoading) {
          return _buildAdContainer(
            loadingWidget ??
                const SizedBox(
                  height: 50,
                  child: Center(child: LinearProgressIndicator()),
                ),
          );
        }

        // If ad failed to load and fallback content is provided, show it
        if (fallbackContent != null) {
          return _buildAdContainer(fallbackContent!);
        }

        // Otherwise, don't take up space
        return const SizedBox(height: 0);
      }),
    );
  }

  Widget _buildAdContainer(Widget content) {
    final container = Container(
      alignment: Alignment.center,
      width: double.infinity,
      decoration:
          useGlassEffect
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
      return GlassAdPanel(borderRadius: borderRadius, child: container);
    }

    return container;
  }
}
