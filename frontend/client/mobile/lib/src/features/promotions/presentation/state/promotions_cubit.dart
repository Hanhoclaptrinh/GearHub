import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/flash_sale_product_model.dart';
import '../../data/models/voucher_model.dart';
import '../../domain/repositories/promotions_repository.dart';
import 'promotions_state.dart';

class PromotionsCubit extends Cubit<PromotionsState> {
  final PromotionsRepository _repository;

  PromotionsCubit({required PromotionsRepository repository})
    : _repository = repository,
      super(PromotionsInitial());

  Future<void> loadData() async {
    emit(PromotionsLoading());

    try {
      final results = await Future.wait([
        _repository.getAvailableVouchers(),
        _repository.getMyVouchers(),
        _repository.getActiveFlashSales(),
      ]);
      final vouchers = results[0] as List<VoucherModel>;
      final myVouchers = results[1] as List<VoucherModel>;
      final flashSales = results[2] as List<FlashSaleProductModel>;
      final claimedIds = myVouchers.map((voucher) => voucher.id).toSet();

      emit(
        PromotionsLoaded(
          vouchers: vouchers,
          flashSales: flashSales,
          claimedIds: claimedIds,
          claimingIds: const <String>{},
        ),
      );
    } catch (e) {
      emit(PromotionsError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> claimVoucher(String voucherId) async {
    final currentState = state;

    if (currentState is! PromotionsLoaded) return;
    if (currentState.claimingIds.contains(voucherId)) return;
    if (currentState.claimedIds.contains(voucherId)) return;

    emit(
      currentState.copyWith(
        claimingIds: {...currentState.claimingIds, voucherId},
      ),
    );

    try {
      await _repository.claimVoucher(voucherId);

      final updatedState = state;
      if (updatedState is PromotionsLoaded) {
        final newClaimingIds = Set<String>.from(updatedState.claimingIds)
          ..remove(voucherId);

        emit(
          updatedState.copyWith(
            claimingIds: newClaimingIds,
            claimedIds: {...updatedState.claimedIds, voucherId},
          ),
        );
      }
    } catch (_) {
      final updatedState = state;

      if (updatedState is PromotionsLoaded) {
        final newClaimingIds = Set<String>.from(updatedState.claimingIds)
          ..remove(voucherId);

        emit(updatedState.copyWith(claimingIds: newClaimingIds));
      }

      rethrow;
    }
  }

  String _extractErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return 'Không thể tải ưu đãi. Vui lòng thử lại.';
  }
}
