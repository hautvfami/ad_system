import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ad_controller.dart';
import '../services/ad_service.dart';
import '../models/ad_types.dart';

/// A stylized button for displaying reward opportunities through ads.
///
/// This widget automatically handles the rewarded ad display logic and
/// provides visual feedback for loading/disabled states.
class RewardedAdButton extends StatelessWidget {
  /// The label to display on the button
  final String label;

  /// Icon to show next to the label
  final IconData icon;

  /// The amount of reward to show
  final int rewardAmount;

  /// The reward type to display (e.g., "coins", "gems", etc.)
  final String rewardType;

  /// Callback when reward is successfully earned
  final Function(int amount, String type) onRewardEarned;

  /// Button style
  final ButtonStyle? style;

  /// Whether to show the amount on the button
  final bool showAmount;

  /// Whether the button should glow to attract attention
  final bool enableGlowEffect;

  const RewardedAdButton({
    required this.label,
    required this.rewardAmount,
    required this.rewardType,
    required this.onRewardEarned,
    this.icon = Icons.movie,
    this.style,
    this.showAmount = true,
    this.enableGlowEffect = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdService adService = Get.find<AdService>();
    final AdController adController = Get.find<AdController>();

    // Use Obx to reactively rebuild when ad loading state changes
    return Obx(() {
      final bool isLoading = adService.rewardedAdLoading.value;
      final bool canShowAd = adController.canShowAd(AdType.rewarded);

      // If the user can't see ads (e.g., premium user), don't show the button
      if (!canShowAd && !isLoading) {
        return const SizedBox.shrink();
      }

      return Container(
        decoration: enableGlowEffect
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              )
            : null,
        child: ElevatedButton.icon(
          style: style ??
              ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon),
          label: Text(
            showAmount ? '$label +$rewardAmount $rewardType' : label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: isLoading ? null : () => _onButtonPressed(adService),
        ),
      );
    });
  }

  Future<void> _onButtonPressed(AdService adService) async {
    final bool shown = await adService.showRewardedAd(
      onRewarded: (type, amount) {
        // Pass the actual reward to the callback
        onRewardEarned(rewardAmount, rewardType);
      },
    );

    if (!shown) {
      Get.snackbar(
        'Quảng cáo chưa sẵn sàng',
        'Đang tải quảng cáo, vui lòng thử lại sau',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Preload for next time
      adService.loadRewardedAd();
    }
  }
}
