import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class UtilitiesGrid extends StatelessWidget {
  const UtilitiesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Tiện ích',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB0B0B0),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                icon: LucideIcons.sparkles,
                title: 'Trợ lý AI',
                subtitle: 'Tìm kiếm thông minh',
                gradient: const [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                isPremium: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGridCard(
                icon: LucideIcons.ticket,
                title: 'Vouchers',
                subtitle: '3 vouchers có sẵn',
                gradient: const [Color(0xFF0A0A0F), Color(0xFF2A2A35)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                icon: LucideIcons.shieldCheck,
                title: 'Bảo hành',
                subtitle: 'Thiết bị của tôi',
                bgColor: Colors.white,
                textColor: const Color(0xFF0A0A0F),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGridCard(
                icon: LucideIcons.headphones,
                title: 'Hỗ trợ',
                subtitle: 'Hỗ trợ 24/7',
                bgColor: Colors.white,
                textColor: const Color(0xFF0A0A0F),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required IconData icon,
    required String title,
    required String subtitle,
    List<Color>? gradient,
    Color? bgColor,
    Color textColor = Colors.white,
    bool isPremium = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: bgColor == Colors.white
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: gradient![0].withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: textColor, size: 24),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'MỚI',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
