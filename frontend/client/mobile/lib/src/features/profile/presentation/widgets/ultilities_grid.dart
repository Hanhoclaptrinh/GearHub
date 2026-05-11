import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_state.dart';

class UtilitiesGrid extends StatelessWidget {
  const UtilitiesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    const textLow = Color(0xFF9191A8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'TIỆN ÍCH HỆ SINH THÁI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: textLow,
              letterSpacing: 2,
            ),
          ),
        ),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildBentoCard(
              icon: LucideIcons.sparkles,
              title: 'Trợ lý AI',
              subtitle: 'Tìm kiếm',
              accent: const Color(0xFF8B5CF6),
              isPremium: true,
            ),
            BlocBuilder<WishlistCubit, WishlistState>(
              builder: (context, state) {
                final count = (state is WishlistLoaded)
                    ? state.products.length
                    : 0;
                return _buildBentoCard(
                  icon: LucideIcons.heart,
                  title: 'Yêu thích',
                  subtitle: '$count món',
                  accent: const Color(0xFFF43F5E),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistPage()),
                  ),
                );
              },
            ),
            _buildBentoCard(
              icon: LucideIcons.ticket,
              title: 'Vouchers',
              subtitle: 'Đang có 3',
              accent: const Color(0xFFFFCC00),
            ),
            _buildBentoCard(
              icon: LucideIcons.shieldCheck,
              title: 'Bảo hành',
              subtitle: 'Quản lý',
              accent: const Color(0xFF10B981),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    bool isPremium = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                if (isPremium)
                  const Icon(
                    LucideIcons.zap,
                    size: 12,
                    color: Color(0xFFFFCC00),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9191A8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
