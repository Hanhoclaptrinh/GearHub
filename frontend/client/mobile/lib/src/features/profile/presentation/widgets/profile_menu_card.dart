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
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            groupLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.2),
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
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
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.white.withValues(alpha: 0.05),
                      indent: 20,
                      endIndent: 20,
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
    if (item.isToggle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch.adaptive(
                value: item.toggleValue ?? false,
                onChanged: item.onToggle,
                activeTrackColor: const Color(
                  0xFFFDE047,
                ).withValues(alpha: 0.3),
                activeColor: const Color(0xFFFDE047),
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.2,
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
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.badge!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.3),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: Colors.white.withValues(alpha: 0.1),
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
