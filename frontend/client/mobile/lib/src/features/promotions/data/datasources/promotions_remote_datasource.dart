import 'package:dio/dio.dart';
import '../models/voucher_model.dart';

class PromotionsRemoteDatasource {
  final Dio dio;

  PromotionsRemoteDatasource({required this.dio});

  Future<List<VoucherModel>> getAvailableVouchers() async {
    try {
      final response = await dio.get('/promotions/available');
      final List data = response.data;
      return data
          .map((json) => VoucherModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<VoucherModel> claimVoucher(String voucherId) async {
    try {
      final response = await dio.post('/promotions/vouchers/$voucherId/claim');
      final voucherData = response.data['voucher'] ?? response.data;
      return VoucherModel.fromJson(voucherData as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<VoucherModel>> getMyVouchers() async {
    try {
      final response = await dio.get('/promotions/me/vouchers');
      final List data = response.data;
      return data
          .map((json) => VoucherModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
