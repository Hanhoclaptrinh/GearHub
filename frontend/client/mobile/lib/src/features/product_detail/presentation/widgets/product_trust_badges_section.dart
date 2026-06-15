import 'package:flutter/material.dart';
import 'package:mobile/src/core/utils/brand_identity_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductTrustBadgesSection extends StatelessWidget {
  final Color accentColor;
  const ProductTrustBadgesSection({super.key, required this.accentColor});

  final List<Map<String, dynamic>> _badges = const [
    {
      'icon': FontAwesomeIcons.shield,
      'title': 'Bảo hành chính hãng',
      'desc':
          'Bảo hành toàn diện lên đến 36 tháng. Quy đổi trực tiếp nếu phát hiện lỗi từ nhà sản xuất.',
    },
    {
      'icon': FontAwesomeIcons.solidTruck,
      'title': 'Vận chuyển hỏa tốc',
      'desc':
          'Giao hàng tiêu chuẩn an toàn và miễn phí đến tận nhà của bạn trong vòng 24 giờ.',
    },
    {
      'icon': FontAwesomeIcons.solidHeadphones,
      'title': 'Đặc quyền chuyên gia',
      'desc':
          'Nhận hỗ trợ trực tiếp từ đội ngũ kỹ thuật viên cao cấp cho bất cứ yêu cầu kỹ thuật nào.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final adaptiveAccent = BrandIdentityHelper.getAdaptiveAccent(
      context,
      accentColor,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'DỊCH VỤ HẬU MÃI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: adaptiveAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          ..._badges.map((b) => _buildBadgeItem(context, b)),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(BuildContext context, Map<String, dynamic> b) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final adaptiveAccent = BrandIdentityHelper.getAdaptiveAccent(
      context,
      accentColor,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: adaptiveAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: adaptiveAccent.withValues(alpha: 0.1)),
            ),
            child: FaIcon(
              b['icon'] as FaIconData,
              size: 20,
              color: adaptiveAccent,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (b['title'] as String).toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  b['desc'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: cs.onSurfaceVariant,
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
