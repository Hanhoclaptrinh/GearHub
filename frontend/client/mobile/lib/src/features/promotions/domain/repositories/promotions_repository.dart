import '../../data/models/voucher_model.dart';

abstract class PromotionsRepository {
  Future<List<VoucherModel>> getAvailableVouchers();
  Future<VoucherModel> claimVoucher(String voucherId);
  Future<List<VoucherModel>> getMyVouchers();
}
