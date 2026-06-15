import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PaymentSelectionSection extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;

  const PaymentSelectionSection({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final bool isCOD = selectedMethod == "COD";
    final containerBg = isDark
        ? const Color(0xFF161619)
        : const Color(0xFFF4F4F5);
    final sliderBg = isDark ? Colors.white : const Color(0xFF111111);
    final borderCol = isDark
        ? const Color(0xFF2A2A2F)
        : const Color(0xFFE4E4E7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phương thức thanh toán",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double segmentWidth = (totalWidth - 8) / 2;

            return Container(
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: containerBg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    alignment: isCOD
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: segmentWidth,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: sliderBg,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!isCOD) {
                              HapticFeedback.selectionClick();
                              onMethodChanged("COD");
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  "assets/logo/cash.svg",
                                  height: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "COD",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isCOD
                                        ? (isDark
                                              ? const Color(0xFF111111)
                                              : Colors.white)
                                        : secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (isCOD) {
                              HapticFeedback.selectionClick();
                              onMethodChanged("PAYMENT_GATEWAY");
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Opacity(
                                  opacity: !isCOD ? 1.0 : 0.55,
                                  child: SvgPicture.asset(
                                    "assets/logo/vnpay.svg",
                                    height: 13,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "VNPay",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: !isCOD
                                        ? (isDark
                                              ? const Color(0xFF111111)
                                              : Colors.white)
                                        : secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: isDark ? const Color(0xFF161619) : const Color(0xFFF9F9FB),
              shape: BeveledRectangleBorder(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                  bottomLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2A2A2F)
                      : const Color(0xFFE4E4E7),
                  width: 0.8,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCOD
                      ? "Thanh toán khi nhận hàng"
                      : "Cổng thanh toán online VNPay",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCOD
                      ? "Fen có thể chọn trả bằng tiền mặt hoặc chuyển khoản trực tiếp cho shipper khi nhận và kiểm tra hàng thành công."
                      : "Thanh toán nhanh chóng, an toàn qua quét mã QR ứng dụng ngân hàng hoặc các loại thẻ ATM, Visa, Mastercard, JCB.",
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
