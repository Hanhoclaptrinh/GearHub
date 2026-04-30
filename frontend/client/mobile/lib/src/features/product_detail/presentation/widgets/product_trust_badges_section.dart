import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductTrustBadgesSection extends StatelessWidget {
  const ProductTrustBadgesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrustBadge(LucideIcons.shieldCheck, 'Bảo hành\n36 tháng'),
            _buildVerticalDivider(),
            _buildTrustBadge(LucideIcons.truck, 'Giao hàng\nhỏa tốc'),
            _buildVerticalDivider(),
            _buildTrustBadge(LucideIcons.badgeCheck, 'Cam kết\nchính hãng'),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFFE5E5EA),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF1C1C1E)),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
