import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/src/features/profile/presentation/pages/edit_profile_page.dart';

class ProfileHeader extends StatelessWidget {
  final UserEntity? user;
  const ProfileHeader({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        children: [
          // ── Profile Identity Section ──
          GestureDetector(
            onTap: user != null
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(user: user!),
                    ),
                  )
                : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse/Glow Effect
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.champagne.withValues(alpha: 0.1),
                        AppColors.champagne.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(52),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF14141E),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: user?.avatarUrl?.isNotEmpty == true
                            ? CachedNetworkImage(
                                imageUrl: user!.avatarUrl!,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorWidget: (_, __, ___) =>
                                    _buildInitialAvatar(),
                              )
                            : _buildInitialAvatar(),
                      ),
                    ),
                  ),
                ),

                if (user != null)
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.champagne,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            (user?.fullName ?? 'KHÁCH HÀNG'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),

          const SizedBox(height: 12),

          if (user != null)
            Text(
              user!.email,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.36),
              ),
            )
          else
            Text(
              'THIẾT LẬP TÀI KHOẢN NGAY',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.2),
                letterSpacing: 1.5,
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
          fontSize: 32,
          fontWeight: FontWeight.w200,
          color: Colors.white24,
        ),
      ),
    );
  }
}
