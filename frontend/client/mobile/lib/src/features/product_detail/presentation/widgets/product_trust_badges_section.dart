import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
                  'Mua ngay tại GearHub,\nnhận thêm nhiều ưu đãi!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0F),
                    letterSpacing: -0.5,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nhận thêm nhiều ưu đãi chính hãng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A8A9E),
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            b['icon'] as IconData,
                            size: 20,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          b['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A0A0F),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            b['desc'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF5C5C6B),
                              height: 1.3,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Learn more
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Tìm hiểu thêm',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A0A0F),
                              decoration: TextDecoration.underline,
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
                color: const Color(0xFFE5E5EA),
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
                            color: const Color(0xFF0A0A0F),
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
