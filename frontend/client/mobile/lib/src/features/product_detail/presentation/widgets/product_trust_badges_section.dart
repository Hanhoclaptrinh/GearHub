import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductTrustBadgesSection extends StatelessWidget {
  final Color accentColor;
  const ProductTrustBadgesSection({super.key, required this.accentColor});

  final List<Map<String, dynamic>> _badges = const [
    {
      'icon': LucideIcons.shieldCheck,
      'title': 'Bảo hành chính hãng',
      'desc':
          'Bảo hành toàn diện lên đến 36 tháng. Quy đổi trực tiếp nếu phát hiện lỗi từ nhà sản xuất.',
    },
    {
      'icon': LucideIcons.truck,
      'title': 'Vận chuyển hỏa tốc',
      'desc':
          'Giao hàng tiêu chuẩn an toàn và miễn phí đến tận nhà của bạn trong vòng 24 giờ.',
    },
    {
      'icon': LucideIcons.headset,
      'title': 'Đặc quyền chuyên gia',
      'desc':
          'Nhận hỗ trợ trực tiếp từ đội ngũ kỹ thuật viên cao cấp cho bất cứ yêu cầu kỹ thuật nào.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 1,
                color: accentColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Text(
                'DỊCH VỤ HẬU MÃI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          ..._badges.map((b) => _buildBadgeItem(b)),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(Map<String, dynamic> b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.1)),
            ),
            child: Icon(b['icon'] as IconData, size: 20, color: accentColor),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (b['title'] as String).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  b['desc'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
