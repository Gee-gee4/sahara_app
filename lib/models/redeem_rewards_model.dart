class RedeemRewardsModel {
  RedeemRewardsModel({
    required this.rewardId,
    required this.rewardName,
    required this.rewardValue,
    required this.rewardTotalValue,
    required this.isInternal,
    required this.isVirtual,
    required this.rewardGroup,
  });

  final int rewardId;
  final String rewardName;
  final double rewardValue;
  final double rewardTotalValue;
  final bool isInternal;
  final bool isVirtual;
  final RewardGroupModel rewardGroup;

  factory RedeemRewardsModel.fromJson(Map<String, dynamic> json) {
    return RedeemRewardsModel(
      rewardId: json['rewardId'],
      rewardName: json['rewardName'] ?? '',
      rewardValue: (json['rewardValue'] ?? 0).toDouble(),
      rewardTotalValue: (json['rewardTotalValue'] ?? 0).toDouble(),
      isInternal: json['isInternal'],
      isVirtual: json['isVirtual'],
      rewardGroup: RewardGroupModel.fromJson(json['rewardGroup']),
    );
  }

  Map<String, dynamic> toJson() => {
        'rewardId': rewardId,
        'rewardName': rewardName,
        'rewardValue': rewardValue,
        'rewardTotalValue': rewardTotalValue,
        'isInternal': isInternal,
        'isVirtual': isVirtual,
        'rewardGroup': rewardGroup.toJson(),
      };
}

class RewardGroupModel {
  RewardGroupModel({
    required this.rewardGroupId,
    required this.rewardGroupName,
  });

  final int rewardGroupId;
  final String rewardGroupName;

  factory RewardGroupModel.fromJson(Map<String, dynamic> json) {
    return RewardGroupModel(
      rewardGroupId: json['rewardGroupId'],
      rewardGroupName: json['rewardGroupName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'rewardGroupId': rewardGroupId,
        'rewardGroupName': rewardGroupName,
      };
}
