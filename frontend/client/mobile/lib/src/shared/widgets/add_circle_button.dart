import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddCircleButton extends StatelessWidget {
  final bool dark;
  final VoidCallback? onTap;

  const AddCircleButton({
    super.key,
    required this.dark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: dark ? 28 : 34,
        height: dark ? 28 : 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark
              ? const Color(0xFF0D0D1A)
              : Colors.white.withValues(alpha: 0.1),
          border: dark
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
        ),
        child: Icon(
          LucideIcons.plus,
          size: dark ? 12 : 14,
          color: dark ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}
