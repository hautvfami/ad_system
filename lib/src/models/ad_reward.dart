/// Represents a reward earned from a rewarded ad
class AdReward {
  /// The type of reward (e.g., "coins", "gems", etc.)
  final String type;

  /// The amount of reward earned
  final int amount;

  /// Creates a new ad reward
  const AdReward({required this.type, required this.amount});

  /// Creates a copy with some fields replaced
  AdReward copyWith({
    String? type,
    int? amount,
  }) {
    return AdReward(
      type: type ?? this.type,
      amount: amount ?? this.amount,
    );
  }

  @override
  String toString() => 'AdReward(type: $type, amount: $amount)';
}
