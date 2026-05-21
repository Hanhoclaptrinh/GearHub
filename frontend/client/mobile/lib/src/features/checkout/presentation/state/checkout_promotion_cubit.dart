import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_promotion_state.dart';
import 'package:mobile/src/features/promotions/data/models/voucher_model.dart';
import 'package:mobile/src/features/promotions/domain/repositories/promotions_repository.dart';

class CheckoutPromotionCubit extends Cubit<CheckoutPromotionState> {
  final PromotionsRepository _repository;

  CheckoutPromotionCubit({required PromotionsRepository repository})
    : _repository = repository,
      super(const CheckoutPromotionState());

  Future<void> loadPromotionData() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final vouchers = await _repository.getMyVouchers();
      emit(
        state.copyWith(
          myVouchers: vouchers,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _extractErrorMessage(e)));
    }
  }

  void selectVoucher(VoucherModel voucher) {
    emit(
      state.copyWith(
        selectedVoucher: voucher,
        clearError: true,
      ),
    );
  }

  void removeVoucher() {
    emit(state.copyWith(clearVoucher: true, clearError: true));
  }

  String _extractErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return e.toString();
  }
}
