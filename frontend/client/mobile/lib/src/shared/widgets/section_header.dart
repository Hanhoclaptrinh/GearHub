import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String index; // Thêm số thứ tự: 01, 02...
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.index,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "$index /",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 0.5,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (actionText != null)
                GestureDetector(
                  onTap: onActionTap,
                  child: Row(
                    children: [
                      Text(
                        actionText!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
