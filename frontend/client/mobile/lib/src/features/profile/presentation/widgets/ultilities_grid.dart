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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 32),
          child: Text(
            'DÀNH RIÊNG CHO BẠN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 1.0,
            ),
          ),
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildEditorialTile(
                    context,
                    icon: LucideIcons.sparkles,
                    title: 'TRỢ LÝ AI',
                    subtitle: 'AI ASSISTANT',
                    height: 180,
                  ),
                  const SizedBox(height: 16),
                  _buildEditorialTile(
                    context,
                    icon: LucideIcons.ticket,
                    title: 'VOUCHERS',
                    subtitle: '3 ACTIVE',
                    height: 120,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  BlocBuilder<WishlistCubit, WishlistState>(
                    builder: (context, state) {
                      final count = (state is WishlistLoaded)
                          ? state.products.length
                          : 0;
                      return _buildEditorialTile(
                        context,
                        icon: LucideIcons.heart,
                        title: 'YÊU THÍCH',
                        subtitle: '$count SẢN PHẨM',
                        height: 130,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WishlistPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildEditorialTile(
                    context,
                    icon: LucideIcons.shieldCheck,
                    title: 'BẢO HÀNH',
                    subtitle: 'PROTECTION',
                    height: 170,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditorialTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double height,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withValues(alpha: 0.02), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFFFDE047)),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
