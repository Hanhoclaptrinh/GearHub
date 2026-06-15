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
    final cs = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    //calculate values based on scroll
    double baseOpacity = isTransparentAtTop
        ? (scrollOffset / maxScroll).clamp(0.0, 1.0)
        : 1.0;
    double blurAmount = isTransparentAtTop
        ? (scrollOffset / (maxScroll / 20)).clamp(0.0, 20.0)
        : 20.0;

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
              color: scaffoldBg.withValues(alpha: baseOpacity * 0.8),
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
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),

                  //not centre title -> top-left
                  if (!centerTitle)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (onBack != null) ...[
                            GestureDetector(
                              onTap: onBack,
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: cs.onSurface,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurface,
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
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: cs.onSurface,
                          size: 24,
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
  final String? badgeText;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget iconWidget = Icon(icon, size: 22, color: color ?? cs.onSurface);

    if (badgeText != null && badgeText!.isNotEmpty) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(left: 8),
        alignment: Alignment.center,
        child: iconWidget,
      ),
    );
  }
}
