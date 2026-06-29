import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ConciergeEmptyState extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;

  const ConciergeEmptyState({super.key, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Tư vấn sản phẩm', LucideIcons.monitorSmartphone),
      ('Hỗ trợ đơn hàng', LucideIcons.packageCheck),
      ('Setup phù hợp', LucideIcons.slidersHorizontal),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Icon(
              LucideIcons.sparkles,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'GearHub có thể hỗ trợ gì cho bạn hôm nay?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tư vấn sản phẩm, đơn hàng hoặc setup phù hợp với không gian của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: categories.map((item) {
              return _PressableSuggestionChip(
                label: item.$1,
                icon: item.$2,
                onTap: () => onSuggestionTap(item.$1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PressableSuggestionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PressableSuggestionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PressableSuggestionChip> createState() => _PressableSuggestionChipState();
}

class _PressableSuggestionChipState extends State<_PressableSuggestionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed ? cs.primary : cs.outlineVariant,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _isPressed ? cs.primary : cs.onSurfaceVariant,
                size: 15,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isPressed ? cs.primary : cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
