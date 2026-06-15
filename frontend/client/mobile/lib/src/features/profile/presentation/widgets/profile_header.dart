import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/src/features/profile/presentation/pages/edit_profile_page.dart';

class ProfileHeader extends StatelessWidget {
  final UserEntity? user;
  const ProfileHeader({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        children: [
          //profile indentity
          //nhấn vào qua trang sửa thông tin
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
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.onSurface.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(52),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
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
                                    _buildInitialAvatar(context),
                              )
                            : _buildInitialAvatar(context),
                      ),
                    ),
                  ),
                ),

                if (user != null)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.ctaMain,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.pencil,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            (user?.fullName ?? 'KHÁCH HÀNG'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
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
                color: cs.onSurface.withValues(alpha: 0.36),
              ),
            )
          else
            Text(
              'THIẾT LẬP TÀI KHOẢN NGAY',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: cs.onSurface.withValues(alpha: 0.2),
                letterSpacing: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        user?.fullName?.isNotEmpty == true
            ? user!.fullName![0].toUpperCase()
            : 'U',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w200,
          color: cs.onSurface.withValues(alpha: 0.24),
        ),
      ),
    );
  }
}
