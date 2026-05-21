import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_promotion_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_promotion_state.dart';
import 'package:mobile/src/features/promotions/data/models/voucher_model.dart';

class PromotionSection extends StatelessWidget {
  final double subtotal;

  const PromotionSection({super.key, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutPromotionCubit, CheckoutPromotionState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ưu đãi",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildVoucherCard(context, state),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCardStrong, width: 0.5),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.slate400,
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, CheckoutPromotionState state) {
    final selected = state.selectedVoucher;
    final hasVoucher = selected != null;

    return GestureDetector(
      onTap: () => _showVoucherBottomSheet(context, state),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasVoucher
              ? AppColors.brandYellowSoft
              : AppColors.cardSurfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasVoucher
                ? AppColors.brandYellow.withValues(alpha: 0.3)
                : AppColors.borderCardStrong,
            width: 0.5,
          ),
        ),
        child: hasVoucher
            ? _buildSelectedVoucher(context, selected)
            : _buildVoucherPlaceholder(state),
      ),
    );
  }

  Widget _buildVoucherPlaceholder(CheckoutPromotionState state) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.brandYellowSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.tag,
            size: 18,
            color: AppColors.brandYellow,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Chọn mã ưu đãi",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                state.myVouchers.isEmpty
                    ? "Bạn chưa có mã ưu đãi nào"
                    : "${state.myVouchers.length} mã có thể dùng",
                style: const TextStyle(fontSize: 12, color: AppColors.slate400),
              ),
            ],
          ),
        ),
        if (state.myVouchers.isNotEmpty)
          const Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: AppColors.slate400,
          ),
      ],
    );
  }

  Widget _buildSelectedVoucher(BuildContext context, VoucherModel voucher) {
    final discount = _calcVoucherDiscount(voucher);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.brandYellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.tag,
            size: 18,
            color: AppColors.brandYellow,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                voucher.code,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.brandYellow,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Giảm ${formatVND(discount)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.emerald400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.read<CheckoutPromotionCubit>().removeVoucher(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceAltAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.x,
              size: 16,
              color: AppColors.slate400,
            ),
          ),
        ),
      ],
    );
  }

  double _calcVoucherDiscount(VoucherModel v) {
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

  void _showVoucherBottomSheet(
    BuildContext context,
    CheckoutPromotionState state,
  ) {
    final cubit = context.read<CheckoutPromotionCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoucherBottomSheet(
        vouchers: state.myVouchers,
        selectedId: state.selectedVoucher?.id,
        subtotal: subtotal,
        onSelect: (voucher) {
          cubit.selectVoucher(voucher);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _VoucherBottomSheet extends StatelessWidget {
  final List<VoucherModel> vouchers;
  final String? selectedId;
  final double subtotal;
  final void Function(VoucherModel) onSelect;

  const _VoucherBottomSheet({
    required this.vouchers,
    this.selectedId,
    required this.subtotal,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderCardStrong, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderCardStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(LucideIcons.tag, size: 20, color: AppColors.brandYellow),
                SizedBox(width: 10),
                Text(
                  "Chọn mã ưu đãi",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderCardStrong, height: 1),
          Flexible(
            child: vouchers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      "Bạn chưa có mã ưu đãi nào.",
                      style: TextStyle(color: AppColors.slate400, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      bottomPadding + 20,
                    ),
                    shrinkWrap: true,
                    itemCount: vouchers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final v = vouchers[index];
                      final eligible = subtotal >= v.minOrderAmount;
                      final isSelected = v.id == selectedId;

                      return _buildVoucherItem(v, eligible, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherItem(VoucherModel v, bool eligible, bool isSelected) {
    return GestureDetector(
      onTap: eligible ? () => onSelect(v) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandYellowSoft
              : eligible
              ? AppColors.cardSurfaceAlt
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.brandYellow.withValues(alpha: 0.4)
                : AppColors.borderCardStrong,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Opacity(
          opacity: eligible ? 1.0 : 0.45,
          child: Row(
            children: [
              // Voucher icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: v.isPercent
                      ? AppColors.brandYellowSoft
                      : AppColors.brandIndigoSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    v.isPercent
                        ? "${v.value.toInt()}%"
                        : formatCompact(v.value),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: v.isPercent ? 16 : 13,
                      color: v.isPercent
                          ? AppColors.brandYellow
                          : AppColors.brandIndigo,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      v.summaryText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate400,
                      ),
                    ),
                    if (!eligible)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Đơn tối thiểu ${formatVND(v.minOrderAmount)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accentPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  LucideIcons.circleCheck,
                  size: 22,
                  color: AppColors.brandYellow,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
