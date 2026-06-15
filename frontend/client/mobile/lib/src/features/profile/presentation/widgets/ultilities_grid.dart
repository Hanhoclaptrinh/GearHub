import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_state.dart';
import 'package:mobile/src/features/promotions/presentation/state/my_vouchers_cubit.dart';

class UtilitiesGrid extends StatelessWidget {
  const UtilitiesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 24),
          child: Text(
            'DÀNH RIÊNG CHO BẠN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withValues(alpha: 0.4),
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
                    icon: FontAwesomeIcons.solidComments,
                    title: 'CONCIERGE',
                    subtitle: 'GEARHUB SUPPORT',
                    height: 180,
                    onTap: () => ConciergeEntryButton.open(context),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<MyVouchersCubit, MyVouchersState>(
                    builder: (context, state) {
                      final count = (state is MyVouchersLoaded)
                          ? state.vouchers.length
                          : 0;
                      return _buildEditorialTile(
                        context,
                        icon: FontAwesomeIcons.ticket,
                        title: 'VOUCHERS',
                        subtitle: '$count CÓ SẴN',
                        height: 120,
                      );
                    },
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
                        icon: FontAwesomeIcons.solidHeart,
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
                    icon: FontAwesomeIcons.shield,
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
    required dynamic icon,
    required String title,
    required String subtitle,
    required double height,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final gradientColors = isDark
        ? [const Color(0xFF161622), const Color(0xFF0F0F14)]
        : [const Color(0xFFFFFFFF), const Color(0xFFF3F4F6)];

    final borderColor = isDark
        ? cs.onSurface.withValues(alpha: 0.05)
        : cs.onSurface.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                bottom: -24,
                right: -24,
                child: Transform.rotate(
                  angle: -0.15,
                  child: FaIcon(
                    icon,
                    size: 90,
                    color: cs.onSurface.withValues(
                      alpha: isDark ? 0.025 : 0.015,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          child: FaIcon(icon, size: 16, color: cs.primary),
                        ),
                        if (onTap != null)
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 14,
                            color: cs.onSurface.withValues(alpha: 0.25),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.35),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
