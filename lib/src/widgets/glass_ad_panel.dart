import 'package:flutter/material.dart';
import 'dart:ui';

import '../utils/ad_colors.dart';

/// A container with glass effect to enhance the visual appearance of ads.
///
/// This widget applies a blur effect and semi-transparent background to make
/// ads look more integrated with the app design.
class GlassAdPanel extends StatelessWidget {
  /// The ad widget to be wrapped with the glass effect.
  final Widget child;

  /// Border radius for the container.
  final double borderRadius;

  /// Blur intensity for the backdrop filter.
  final double blurIntensity;

  /// Background color opacity.
  final double opacity;

  const GlassAdPanel({
    required this.child,
    this.borderRadius = 24,
    this.blurIntensity = 24,
    this.opacity = 0.15,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurIntensity,
          sigmaY: blurIntensity,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AdColors.overlay.withOpacity(opacity),
            border: Border.all(color: AdColors.borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
