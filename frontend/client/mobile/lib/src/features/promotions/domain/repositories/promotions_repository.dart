import '../../data/models/voucher_model.dart';
import '../../data/models/reward_points_model.dart';

abstract class PromotionsRepository {
  Future<List<VoucherModel>> getAvailableVouchers();
  Future<RewardPointsModel> getMyRewardPoints();
  Future<VoucherModel> claimVoucher(String voucherId);
  Future<List<VoucherModel>> getMyVouchers();
}
