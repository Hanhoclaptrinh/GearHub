import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileMenuCard extends StatelessWidget {
  final String groupLabel;
  final List<ProfileMenuItem> items;

  const ProfileMenuCard({
    super.key,
    required this.groupLabel,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            groupLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF9191A8),
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 0.8,
            ),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  _MenuItemWidget(item: item),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItemWidget extends StatelessWidget {
  final ProfileMenuItem item;

  const _MenuItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    const textHigh = Colors.white;
    const textLow = Color(0xFF9191A8);
    const accent = Color(0xFF3B82F6);

    if (item.isToggle) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 20, color: textLow),
                  const SizedBox(width: 16),
                ],
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textHigh,
                  ),
                ),
              ],
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch.adaptive(
                value: item.toggleValue ?? false,
                onChanged: item.onToggle,
                activeTrackColor: accent,
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          item.onTap?.call();
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 20, color: textLow),
                    const SizedBox(width: 16),
                  ],
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textHigh,
                    ),
                  ),
                  if (item.badge != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.badge!,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Color(0xFF4A4A62),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMenuItem {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? badge;
  final bool isToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;

  const ProfileMenuItem({
    required this.title,
    this.icon,
    this.onTap,
    this.badge,
    this.isToggle = false,
    this.toggleValue,
    this.onToggle,
  });
}
