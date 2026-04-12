import 'dart:ui';
import 'package:flutter/material.dart';

class OnboardingGlassCard extends StatelessWidget {
  final String imageUrl;
  final double? height;

  const OnboardingGlassCard({super.key, required this.imageUrl, this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color glassColor = isDark ? Colors.white : Colors.black;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.2)
        : Colors.black.withOpacity(0.1);
    final Color shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.1);

    return Container(
      width: double.infinity,
      height: height ?? 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // glass
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      glassColor.withOpacity(isDark ? 0.15 : 0.05),
                      glassColor.withOpacity(isDark ? 0.05 : 0.01),
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0, 0.4, 0.5, 1],
                    colors: [
                      glassColor.withOpacity(isDark ? 0.1 : 0.05),
                      Colors.transparent,
                      Colors.transparent,
                      glassColor.withOpacity(isDark ? 0.05 : 0.02),
                    ],
                  ),
                ),
              ),
            ),

            // img
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.error_outline,
                    color: isDark ? Colors.white24 : Colors.black26,
                    size: 48,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
