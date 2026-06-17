import '../../data/models/flash_sale_product_model.dart';
import '../../data/models/voucher_model.dart';

abstract class PromotionsRepository {
  Future<List<VoucherModel>> getAvailableVouchers();
  Future<VoucherModel> claimVoucher(String voucherId);
  Future<List<VoucherModel>> getMyVouchers();
  Future<List<FlashSaleProductModel>> getActiveFlashSales();
}
