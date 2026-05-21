import 'package:equatable/equatable.dart';
import '../../data/models/voucher_model.dart';

abstract class PromotionsState extends Equatable {
  const PromotionsState();

  @override
  List<Object?> get props => [];
}

class PromotionsInitial extends PromotionsState {}

class PromotionsLoading extends PromotionsState {}

class PromotionsLoaded extends PromotionsState {
  final List<VoucherModel> vouchers;
  final Set<String> claimingIds;
  final Set<String> claimedIds;

  const PromotionsLoaded({
    required this.vouchers,
    this.claimingIds = const {},
    this.claimedIds = const {},
  });

  PromotionsLoaded copyWith({
    List<VoucherModel>? vouchers,
    Set<String>? claimingIds,
    Set<String>? claimedIds,
  }) {
    return PromotionsLoaded(
      vouchers: vouchers ?? this.vouchers,
      claimingIds: claimingIds ?? this.claimingIds,
      claimedIds: claimedIds ?? this.claimedIds,
    );
  }

  @override
  List<Object?> get props => [vouchers, claimingIds, claimedIds];
}

class PromotionsError extends PromotionsState {
  final String message;

  const PromotionsError({required this.message});

  @override
  List<Object> get props => [message];
}
