import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFF6366F1);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);

class ProductTrustBadgesSection extends StatefulWidget {
  const ProductTrustBadgesSection({super.key});

  @override
  State<ProductTrustBadgesSection> createState() =>
      _ProductTrustBadgesSectionState();
}

class _ProductTrustBadgesSectionState extends State<ProductTrustBadgesSection> {
  double _scrollProgress = 0.0;

  final List<Map<String, dynamic>> _badges = [
    {
      'icon': LucideIcons.shieldCheck,
      'title': 'Bảo hành chính hãng',
      'desc':
          'Bảo hành toàn diện lên đến 36 tháng cho mọi sản phẩm\nQuy đổi trực tiếp nếu phát hiện lỗi từ nhà sản xuất.',
    },
    {
      'icon': LucideIcons.truck,
      'title': 'Miễn phí vận chuyển',
      'desc':
          'Giao hàng tiêu chuẩn an toàn và miễn phí đến tận nhà của bạn, hoặc nhận hàng tại cửa hàng gần nhất.',
    },
    {
      'icon': LucideIcons.headset,
      'title': 'Hỗ trợ trực tuyến',
      'desc':
          'Nhận hỗ trợ trực tuyến từ đội ngũ kỹ thuật viên và CSKH cho bất cứ yêu cầu nào của bạn.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.82;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DỊCH VỤ HẬU MÃI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ĐẶC QUYỀN TỪ GEARHUB',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _textHigh,
                    letterSpacing: -0.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 250,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.maxScrollExtent > 0) {
                  setState(() {
                    _scrollProgress =
                        notification.metrics.pixels /
                        notification.metrics.maxScrollExtent;
                    _scrollProgress = _scrollProgress.clamp(0.0, 1.0);
                  });
                }
                return true;
              },
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: _badges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final b = _badges[index];
                  return Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: _border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _surfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                          ),
                          child: Icon(
                            b['icon'] as IconData,
                            size: 24,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          (b['title'] as String).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _textHigh,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            b['desc'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textMid.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),

                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: const Text(
                              'TÌM HIỂU THÊM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _textHigh,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Container(
              width: double.infinity,
              height: 3,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(1.5),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;
                  final thumbWidth = trackWidth * 0.4;
                  final maxTravel = trackWidth - thumbWidth;
                  return Stack(
                    children: [
                      Positioned(
                        left: _scrollProgress * maxTravel,
                        child: Container(
                          width: thumbWidth,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _textMid,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
