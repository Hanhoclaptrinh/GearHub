import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_promotion_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_promotion_state.dart';
import 'package:mobile/src/features/promotions/data/models/voucher_model.dart';

class PromotionSection extends StatelessWidget {
  final double subtotal;

  const PromotionSection({super.key, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);

    return BlocBuilder<CheckoutPromotionCubit, CheckoutPromotionState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ưu đãi",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildVoucherCard(context, state),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: hasVoucher
            ? _buildSelectedVoucher(context, selected)
            : _buildVoucherPlaceholder(context, state),
      ),
    );
  }

  Widget _buildVoucherPlaceholder(
    BuildContext context,
    CheckoutPromotionState state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);

    return Row(
      children: [
        FaIcon(FontAwesomeIcons.tag, size: 20, color: primaryTextColor),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Chọn mã ưu đãi",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                state.myVouchers.isEmpty
                    ? "Bạn chưa có mã ưu đãi nào"
                    : "${state.myVouchers.length} mã có thể dùng",
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
            ],
          ),
        ),
        Icon(LucideIcons.chevronRight, size: 18, color: secondaryTextColor),
      ],
    );
  }

  Widget _buildSelectedVoucher(BuildContext context, VoucherModel voucher) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final discount = _calcVoucherDiscount(voucher);

    return Row(
      children: [
        FaIcon(FontAwesomeIcons.tag, size: 20, color: primaryTextColor),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                voucher.code,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: primaryTextColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Giảm ${formatVND(discount)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.read<CheckoutPromotionCubit>().removeVoucher(),
          child: Icon(LucideIcons.x, size: 18, color: secondaryTextColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final dividerColor = isDark
        ? const Color(0xFF2A2A2F)
        : const Color(0xFFE4E4E7);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final sheetBgColor = isDark ? const Color(0xFF121214) : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: dividerColor, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.tag, size: 20, color: primaryTextColor),
                const SizedBox(width: 10),
                Text(
                  "Chọn mã ưu đãi",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: dividerColor, height: 1),
          Flexible(
            child: vouchers.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      "Bạn chưa có mã ưu đãi nào.",
                      style: TextStyle(color: secondaryTextColor, fontSize: 14),
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
                    separatorBuilder: (_, __) => Divider(
                      color: dividerColor,
                      height: 24,
                      thickness: 0.5,
                    ),
                    itemBuilder: (_, index) {
                      final v = vouchers[index];
                      final eligible = subtotal >= v.minOrderAmount;
                      final isSelected = v.id == selectedId;

                      return _buildVoucherItem(
                        context,
                        v,
                        eligible,
                        isSelected,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherItem(
    BuildContext context,
    VoucherModel v,
    bool eligible,
    bool isSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);

    return GestureDetector(
      onTap: eligible ? () => onSelect(v) : null,
      child: Container(
        color: Colors.transparent,
        child: Opacity(
          opacity: eligible ? 1.0 : 0.45,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E22)
                      : const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    v.isPercent
                        ? "${v.value.toInt()}%"
                        : formatCompact(v.value),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: v.isPercent ? 16 : 13,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.code,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: primaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      v.summaryText,
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                    if (!eligible)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Đơn tối thiểu ${formatVND(v.minOrderAmount)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  LucideIcons.circleCheck,
                  size: 22,
                  color: primaryTextColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
