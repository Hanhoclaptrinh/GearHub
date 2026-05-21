class RewardPointsModel {
  final int rewardPoints;
  final double totalSpent;

  const RewardPointsModel({
    required this.rewardPoints,
    required this.totalSpent,
  });

  factory RewardPointsModel.fromJson(Map<String, dynamic> json) {
    return RewardPointsModel(
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
    );
  }

  // tính hạng thành viên dựa trên tổng chi tiêu
  String get tierName {
    if (totalSpent >= 150000000) return 'VIP';
    if (totalSpent >= 50000000) return 'KIM CƯƠNG';
    if (totalSpent >= 15000000) return 'VÀNG';
    return 'BẠC';
  }

  // tính tiến trình tới hạng tiếp theo
  double get tierProgress {
    if (totalSpent >= 150000000) return 1.0;
    if (totalSpent >= 50000000) return (totalSpent - 50000000) / 100000000;
    if (totalSpent >= 15000000) return (totalSpent - 15000000) / 35000000;
    return totalSpent / 15000000;
  }

  String get nextTierName {
    if (totalSpent >= 150000000) return 'VIP';
    if (totalSpent >= 50000000) return 'KIM CƯƠNG';
    if (totalSpent >= 15000000) return 'VÀNG';
    return 'BẠC';
  }
}
