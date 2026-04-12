import 'package:flutter/material.dart';

class OnboardingIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const OnboardingIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // progress bar width
    final double totalWidth = size.width * 0.5;
    const double height = 6.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // progress bar
        Container(
          width: totalWidth,
          height: height,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: (totalWidth / count) * (currentIndex + 1),
                height: height,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
