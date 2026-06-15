import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import '../../data/models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: cs.error.withValues(alpha: 0.15),
        child: Icon(LucideIcons.trash2, color: cs.error, size: 20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : cs.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryIcon(context),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: notification.isRead
                                  ? cs.onSurface.withValues(alpha: 0.8)
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getRelativeTime(notification.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: notification.isRead
                            ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                            : cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              if (!notification.isRead) ...[
                const SizedBox(width: 10),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.brandIndigo,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (notification.type.toUpperCase()) {
      case 'ORDER':
        iconData = LucideIcons.package;
        iconColor = cs.secondary;
        bgColor = cs.secondary.withValues(alpha: 0.1);
        break;
      case 'PAYMENT':
        iconData = LucideIcons.creditCard;
        iconColor = cs.success;
        bgColor = cs.success.withValues(alpha: 0.1);
        break;
      case 'VOUCHER':
      case 'PROMOTION':
        iconData = LucideIcons.ticket;
        iconColor = AppColors.accentPink;
        bgColor = AppColors.accentPink.withValues(alpha: isDark ? 0.1 : 0.15);
        break;
      case 'CHAT':
        iconData = LucideIcons.messageSquare;
        iconColor = AppColors.brandIndigo;
        bgColor = AppColors.brandIndigoSoft;
        break;
      case 'SYSTEM':
      default:
        iconData = LucideIcons.shieldAlert;
        iconColor = cs.info;
        bgColor = cs.info.withValues(alpha: 0.1);
        break;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(child: Icon(iconData, color: iconColor, size: 20)),
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return formatDate(dateTime);
    }
  }
}
