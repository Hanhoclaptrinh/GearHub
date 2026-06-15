import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DeliverySection extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final VoidCallback onEdit;

  const DeliverySection({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasInfo = name.isNotEmpty && address.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final dividerColor = isDark
        ? const Color(0xFF2A2A2F)
        : const Color(0xFFE4E4E7);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161619) : const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2F) : const Color(0xFFE4E4E7),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "ĐỊA CHỈ GIAO HÀNG",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: secondaryTextColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onEdit,
                child: Text(
                  hasInfo ? "Chỉnh sửa" : "Thêm địa chỉ",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: primaryTextColor,
                    decorationThickness: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasInfo) ...[
            Text(
              name.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: primaryTextColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 0.5, color: dividerColor),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaIcon(
                  FontAwesomeIcons.locationDot,
                  size: 16,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 24,
                        color: secondaryTextColor.withValues(alpha: .5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "CHẠM ĐỂ THÊM ĐỊA CHỈ GIAO HÀNG",
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryTextColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
