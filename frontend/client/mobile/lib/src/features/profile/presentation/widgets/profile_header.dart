import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/src/features/profile/presentation/pages/membership_tier_page.dart';
import 'package:mobile/src/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_state.dart';

class ProfileHeader extends StatelessWidget {
  final UserEntity? user;
  const ProfileHeader({super.key, this.user});

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    const textLow = Color(0xFF9191A8);
    const accent = Color(0xFF3B82F6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: user != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(user: user!),
                      ),
                    );
                  }
                : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.1),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: user?.avatarUrl?.isNotEmpty == true
                            ? CachedNetworkImage(
                                imageUrl: user!.avatarUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _buildInitialAvatar(),
                              )
                            : _buildInitialAvatar(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            (user?.fullName ?? 'KHÁCH HÀNG').toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),

          if (user != null) ...[
            BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) {
                double totalSpent = 0.0;
                if (state is OrdersLoaded) {
                  for (final order in state.orders) {
                    if (order['status'] == 'DELIVERED') {
                      totalSpent += _toDouble(
                        order['totalAmount'] ?? order['total'],
                      );
                    }
                  }
                }

                String tierName = 'STANDARD';
                Color tierColor = const Color(0xFF94A3B8);
                IconData tierIcon = LucideIcons.shield;

                if (totalSpent >= 150000000.0) {
                  tierName = 'VIP PRESTIGE';
                  tierColor = const Color(0xFFEF4444);
                  tierIcon = LucideIcons.crown;
                } else if (totalSpent >= 50000000.0) {
                  tierName = 'DIAMOND ELITE';
                  tierColor = const Color(0xFF06B6D4);
                  tierIcon = LucideIcons.gem;
                } else if (totalSpent >= 15000000.0) {
                  tierName = 'GOLD MEMBER';
                  tierColor = const Color(0xFFFFCC00);
                  tierIcon = LucideIcons.sparkles;
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MembershipTierPage(totalSpent: totalSpent),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tierColor.withValues(alpha: 0.15),
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tierIcon, size: 10, color: tierColor),
                        const SizedBox(width: 6),
                        Text(
                          tierName,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: tierColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ] else
            const Text(
              'Tham gia GearHub ngay hôm nay',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textLow,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar() {
    return Center(
      child: Text(
        user?.fullName?.isNotEmpty == true
            ? user!.fullName![0].toUpperCase()
            : 'U',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
