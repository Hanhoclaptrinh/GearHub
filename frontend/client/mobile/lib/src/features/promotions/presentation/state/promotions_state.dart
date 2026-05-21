import 'package:equatable/equatable.dart';
import '../../data/models/voucher_model.dart';
import '../../data/models/reward_points_model.dart';

abstract class PromotionsState extends Equatable {
  const PromotionsState();

  @override
  List<Object?> get props => [];
}

class PromotionsInitial extends PromotionsState {}

class PromotionsLoading extends PromotionsState {}

class PromotionsLoaded extends PromotionsState {
  final List<VoucherModel> vouchers;
  final RewardPointsModel? rewardPoints;
  final Set<String> claimingIds;
  final Set<String> claimedIds;

  const PromotionsLoaded({
    required this.vouchers,
    this.rewardPoints,
    this.claimingIds = const {},
    this.claimedIds = const {},
  });

  PromotionsLoaded copyWith({
    List<VoucherModel>? vouchers,
    RewardPointsModel? rewardPoints,
    Set<String>? claimingIds,
    Set<String>? claimedIds,
  }) {
    return PromotionsLoaded(
      vouchers: vouchers ?? this.vouchers,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      claimingIds: claimingIds ?? this.claimingIds,
      claimedIds: claimedIds ?? this.claimedIds,
    );
  }

  @override
  List<Object?> get props => [vouchers, rewardPoints, claimingIds, claimedIds];
}

class PromotionsError extends PromotionsState {
  final String message;

  const PromotionsError({required this.message});

  @override
  List<Object> get props => [message];
}
