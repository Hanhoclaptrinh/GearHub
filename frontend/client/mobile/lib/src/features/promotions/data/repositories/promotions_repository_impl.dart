import '../datasources/promotions_remote_datasource.dart';
import '../../domain/repositories/promotions_repository.dart';
import '../models/voucher_model.dart';
import '../models/reward_points_model.dart';

class PromotionsRepositoryImpl implements PromotionsRepository {
  final PromotionsRemoteDatasource remoteDatasource;

  PromotionsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<VoucherModel>> getAvailableVouchers() async {
    try {
      return await remoteDatasource.getAvailableVouchers();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<RewardPointsModel> getMyRewardPoints() async {
    try {
      return await remoteDatasource.getMyRewardPoints();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<VoucherModel> claimVoucher(String voucherId) async {
    try {
      return await remoteDatasource.claimVoucher(voucherId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<VoucherModel>> getMyVouchers() async {
    try {
      return await remoteDatasource.getMyVouchers();
    } catch (e) {
      rethrow;
    }
  }
}
