import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/ad_skeleton_type.dart';

/// A widget that provides error handling and fallback content for ad loading failures.
///
/// This widget shows custom content when an ad fails to load,
/// along with options to retry loading or report issues.
class AdErrorFallback extends StatelessWidget {
  /// The error message
  final String? errorMessage;

  /// Callback when user wants to retry loading the ad
  final VoidCallback? onRetry;

  /// Callback when user reports an issue
  final VoidCallback? onReport;

  /// Whether to show the report button
  final bool showReportButton;

  /// Size constraints
  final BoxConstraints? constraints;

  /// Custom error widget to display instead of default
  final Widget? customErrorWidget;

  /// Background color
  final Color? backgroundColor;

  /// Border radius
  final double borderRadius;

  const AdErrorFallback({
    Key? key,
    this.errorMessage,
    this.onRetry,
    this.onReport,
    this.showReportButton = true,
    this.constraints,
    this.customErrorWidget,
    this.backgroundColor,
    this.borderRadius = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If custom error widget is provided, return it
    if (customErrorWidget != null) {
      return customErrorWidget!;
    }

    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ??
        (theme.brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[200]);

    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: theme.brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Ad content unavailable',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ),
          ],
          if (showReportButton && onReport != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onReport,
              child: const Text('Report Issue'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );

    // Apply constraints if provided
    if (constraints != null) {
      content = ConstrainedBox(
        constraints: constraints!,
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: content,
    );
  }
}

/// A widget that handles the loading, error and successful states of ad loading.
///
/// This widget will show:
/// - A skeleton loader during loading
/// - Error fallback when ad fails to load
/// - The ad content when successfully loaded
class AdStateHandler extends StatelessWidget {
  /// Whether the ad is currently loading
  final bool isLoading;

  /// Whether the ad failed to load
  final bool hasError;

  /// Error message when ad fails to load
  final String? errorMessage;

  /// Callback to retry loading the ad
  final VoidCallback? onRetry;

  /// Widget to show when ad is loaded successfully
  final Widget adWidget;

  /// Widget to show during loading
  final Widget? loadingWidget;

  /// Widget to show on error
  final Widget? errorWidget;

  /// Height of the skeleton loader
  final double skeletonHeight;

  /// Whether to show debug info (like error messages)
  final bool showDebugInfo;

  const AdStateHandler({
    Key? key,
    required this.isLoading,
    required this.hasError,
    required this.adWidget,
    this.errorMessage,
    this.onRetry,
    this.loadingWidget,
    this.errorWidget,
    this.skeletonHeight = 250,
    this.showDebugInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show loading widget
    if (isLoading) {
      return loadingWidget ?? _buildDefaultLoadingWidget();
    }

    // Show error widget
    if (hasError) {
      if (errorWidget != null) return errorWidget!;

      return AdErrorFallback(
        errorMessage: showDebugInfo ? errorMessage : null,
        onRetry: onRetry,
        constraints: BoxConstraints(
          minHeight: skeletonHeight,
        ),
      );
    }

    // Show the ad
    return adWidget;
  }

  Widget _buildDefaultLoadingWidget() {
    return AdSkeletonLoader(
      height: skeletonHeight,
    );
  }
}

/// A skeleton loader widget for ads.
///
/// Shows a shimmering placeholder while the ad is loading,
/// helping maintain UI consistency and indicating to users that
/// content is loading.
class AdSkeletonLoader extends StatelessWidget {
  /// Height of the skeleton loader
  final double height;

  /// Width of the skeleton loader (defaults to full width)
  final double? width;

  /// Border radius of the skeleton container
  final double borderRadius;

  /// Base color for the shimmer effect
  final Color baseColor;

  /// Highlight color for the shimmer effect
  final Color highlightColor;

  /// Type of skeleton to show (default, banner, native)
  final AdSkeletonType type;

  const AdSkeletonLoader({
    this.height = 250,
    this.width,
    this.borderRadius = 16,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFFFFFFF),
    this.type = AdSkeletonType.native,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a darker shade for dark theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final effectiveBaseColor = isDarkMode ? const Color(0xFF303030) : baseColor;
    final effectiveHighlightColor =
        isDarkMode ? const Color(0xFF505050) : highlightColor;

    return Shimmer.fromColors(
      baseColor: effectiveBaseColor,
      highlightColor: effectiveHighlightColor,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: _buildSkeletonContent(),
      ),
    );
  }

  Widget _buildSkeletonContent() {
    switch (type) {
      case AdSkeletonType.banner:
        return _buildBannerSkeleton();
      case AdSkeletonType.interstitial:
        return _buildInterstitialSkeleton();
      case AdSkeletonType.native:
      default:
        return _buildNativeSkeleton();
    }
  }

  Widget _buildBannerSkeleton() {
    return Row(
      children: [
        // Icon/logo area
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // Text content
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 12,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 140,
                  height: 10,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),

        // CTA
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNativeSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media area (image)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
            ),
          ),
        ),
        // Text content area
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ad badge
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 36,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Headline
                Container(
                  width: double.infinity,
                  height: 18,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                // Body text lines
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity * 0.65,
                  height: 12,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                // Call to action button
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterstitialSkeleton() {
    // This is just a placeholder, as interstitials are fullscreen
    // and usually wouldn't use a skeleton loader in the UI
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 120,
          height: 16,
          color: Colors.white,
        ),
      ],
    );
  }
}
