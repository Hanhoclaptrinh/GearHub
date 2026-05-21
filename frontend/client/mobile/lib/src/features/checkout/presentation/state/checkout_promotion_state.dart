import 'package:equatable/equatable.dart';
import 'package:mobile/src/features/promotions/data/models/voucher_model.dart';

class CheckoutPromotionState extends Equatable {
  final List<VoucherModel> myVouchers;
  final VoucherModel? selectedVoucher;
  final bool isLoading;
  final String? error;

  const CheckoutPromotionState({
    this.myVouchers = const [],
    this.selectedVoucher,
    this.isLoading = false,
    this.error,
  });

  CheckoutPromotionState copyWith({
    List<VoucherModel>? myVouchers,
    VoucherModel? selectedVoucher,
    bool clearVoucher = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CheckoutPromotionState(
      myVouchers: myVouchers ?? this.myVouchers,
      selectedVoucher: clearVoucher
          ? null
          : (selectedVoucher ?? this.selectedVoucher),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  double calculateVoucherDiscount(double subtotal) {
    if (selectedVoucher == null) return 0;
    final v = selectedVoucher!;

    if (subtotal < v.minOrderAmount) return 0;

    double discount = 0;
    if (v.isPercent) {
      discount = subtotal * (v.value / 100);
      if (v.maxDiscountAmount != null && v.maxDiscountAmount! > 0) {
        discount = discount < v.maxDiscountAmount!
            ? discount
            : v.maxDiscountAmount!;
      }
    } else {
      discount = v.value;
    }
    return discount < subtotal ? discount : subtotal;
  }

  double totalDiscount(double subtotal) {
    return calculateVoucherDiscount(subtotal);
  }

  @override
  List<Object?> get props => [
    myVouchers,
    selectedVoucher,
    isLoading,
    error,
  ];
}
