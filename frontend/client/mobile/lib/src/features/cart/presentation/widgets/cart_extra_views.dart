import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFF59E0B);
const _accentSoft = Color(0x26F59E0B);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class PromoSection extends StatelessWidget {
  const PromoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.ticket, color: _accent, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Áp dụng vouchers',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _textHigh,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mở khóa giảm giá đặc biệt',
                  style: TextStyle(color: _textMid, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: _textLow, size: 18),
        ],
      ),
    );
  }
}

class EmptyCartView extends StatelessWidget {
  final VoidCallback onStartShopping;

  const EmptyCartView({super.key, required this.onStartShopping});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _accentSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accent.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: const Icon(
                LucideIcons.shoppingCart,
                size: 56,
                color: _accent,
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'GIỎ HÀNG RỖNG',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textHigh,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có sản phẩm nào trong giỏ hàng.\nHãy khám phá ngay!',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMid, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: onStartShopping,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.shoppingBag,
                      color: Colors.black,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "BẮT ĐẦU MUA SẮM",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
