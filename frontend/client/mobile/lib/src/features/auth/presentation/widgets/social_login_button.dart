import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;
  final bool isFilled;
  final Color? fillColor;
  final Color? textColor;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.iconPath,
    required this.onTap,
    this.isFilled = false,
    this.fillColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isFilled
              ? (fillColor ?? const Color(0xFF14141E))
              : const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isFilled
                    ? (textColor ?? Colors.white)
                    : Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildIcon() {
    switch (iconPath) {
      case 'google':
        return SvgPicture.asset(
          'assets/logo/google-icon.svg',
          width: 22,
          height: 22,
        );
      case 'facebook':
        return SvgPicture.asset(
          'assets/logo/facebook-icon.svg',
          width: 22,
          height: 22,
        );
      default:
        return const SizedBox(width: 22, height: 22);
    }
  }
}

class SocialIconButton extends StatelessWidget {
  final String type;
  final VoidCallback onTap;

  const SocialIconButton({super.key, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: _buildIcon()),
      ),
    );
  }


  Widget _buildIcon() {
    switch (type) {
      case 'google':
        return SvgPicture.asset(
          'assets/logo/google-icon.svg',
          width: 24,
          height: 24,
        );
      case 'facebook':
        return SvgPicture.asset(
          'assets/logo/facebook-icon.svg',
          width: 24,
          height: 24,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
