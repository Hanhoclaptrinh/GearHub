import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PrivilegeStrip extends StatelessWidget {
  const PrivilegeStrip({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      PrivilegeItem(
        icon: LucideIcons.truck,
        title: 'Priority Delivery',
        subtitle: 'Ưu tiên giao hàng cho đơn đủ điều kiện',
      ),
      PrivilegeItem(
        icon: LucideIcons.headphones,
        title: 'Concierge Support',
        subtitle: 'Hỗ trợ tư vấn sản phẩm cao cấp',
      ),
      PrivilegeItem(
        icon: LucideIcons.badgePercent,
        title: 'Member Pricing',
        subtitle: 'Giá riêng cho thành viên thân thiết',
      ),
    ];

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => items[index],
      ),
    );
  }
}

class PrivilegeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const PrivilegeItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 178,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 17),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
