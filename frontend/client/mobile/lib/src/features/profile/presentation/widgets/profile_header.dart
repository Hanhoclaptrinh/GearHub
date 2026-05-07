import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/src/features/profile/presentation/pages/membership_tier_page.dart';
import 'package:mobile/src/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_state.dart';

const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFF59E0B);
const _textHigh = Color(0xFFF1F1F5);
const _textLow = Color(0xFF4A4A62);

Color startColor = const Color(0xFF64748B);
Color endColor = const Color(0xFF94A3B8);
Color fgColor = const Color(0xFF475569);

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

class ProfileHeader extends StatelessWidget {
  final UserEntity? user;
  const ProfileHeader({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: user != null
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditProfilePage(user: user!)),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: user?.avatarUrl?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: user!.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white24,
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildInitialAvatar(),
                      )
                    : _buildInitialAvatar(),
              ),
            ),
            const SizedBox(width: 16),
            // name & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'Fen GearHub',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textHigh,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'Tham gia GearHub ngay hôm nay',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textLow,
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 10),
                    BlocBuilder<OrdersCubit, OrdersState>(
                      builder: (context, state) {
                        double totalSpent = 0.0;
                        if (state is OrdersLoaded) {
                          for (final order in state.orders) {
                            final String s = order['status'] ?? 'PENDING';
                            if (s == 'DELIVERED') {
                              totalSpent += _toDouble(
                                order['totalAmount'] ?? order['total'],
                              );
                            }
                          }
                        }

                        if (totalSpent == 0.0) return const SizedBox.shrink();

                        String tierName = 'BẠC';
                        IconData tierIcon = LucideIcons.shield;

                        if (totalSpent >= 150000000.0) {
                          tierName = 'VIP MEMBER';
                          startColor = const Color(0xFFEF4444);
                          endColor = const Color(0xFFEC4899);
                          fgColor = Colors.white;
                          tierIcon = LucideIcons.crown;
                        } else if (totalSpent >= 50000000.0) {
                          tierName = 'KIM CƯƠNG';
                          startColor = const Color(0xFF06B6D4);
                          endColor = const Color(0xFF3B82F6);
                          fgColor = Colors.white;
                          tierIcon = LucideIcons.gem;
                        } else if (totalSpent >= 15000000.0) {
                          tierName = 'VÀNG';
                          startColor = const Color(0xFFF59E0B);
                          endColor = const Color(0xFFFCD34D);
                          fgColor = Colors.white;
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
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [startColor, endColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(tierIcon, size: 12, color: startColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    tierName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: startColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
          letterSpacing: -1,
        ),
      ),
    );
  }
}
