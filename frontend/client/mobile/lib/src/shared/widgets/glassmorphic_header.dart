import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicHeader extends StatelessWidget {
  final double scrollOffset;
  final String title;
  final List<Widget>? actions;
  final double maxScroll;
  final VoidCallback? onBack;
  final bool isTransparentAtTop;
  final bool centerTitle;

  const GlassmorphicHeader({
    super.key,
    required this.scrollOffset,
    required this.title,
    this.actions,
    this.maxScroll = 300,
    this.onBack,
    this.isTransparentAtTop = true,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    // calculate values based on scroll
    double baseOpacity = isTransparentAtTop
        ? (scrollOffset / maxScroll).clamp(0.0, 1.0)
        : 1.0;
    double blurAmount = isTransparentAtTop
        ? (scrollOffset / (maxScroll / 20)).clamp(0.0, 20.0)
        : 20.0;

    const bg = Color(0xFF07070A);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            height: topPadding + 60,
            decoration: BoxDecoration(
              color: bg.withValues(alpha: baseOpacity * 0.8),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
              child: Stack(
                children: [
                  if (centerTitle)
                    Center(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),

                  // not centre title -> top-left
                  if (!centerTitle)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (onBack != null) ...[
                            GestureDetector(
                              onTap: onBack,
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (centerTitle && onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: onBack,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),

                  if (actions != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, size: 18, color: color ?? Colors.white),
      ),
    );
  }
}
