import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile/src/features/onboarding/presentation/widgets/three_animated_arrow.dart';

class SlideToActionButton extends StatefulWidget {
  final VoidCallback onAction;
  final String text;

  const SlideToActionButton({
    super.key,
    required this.onAction,
    this.text = 'Bắt đầu',
  });

  @override
  State<SlideToActionButton> createState() => _SlideToActionButtonState();
}

class _SlideToActionButtonState extends State<SlideToActionButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isFinished = false;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _snapAnimation = Tween<double>(begin: 0, end: 0).animate(_snapController);
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isFinished) return;
    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(0.0, maxDrag);
    });
  }

  void _handleDragEnd(DragEndDetails details, double maxDrag) {
    if (_isFinished) return;

    if (_dragPosition >= maxDrag * 0.8) {
      setState(() {
        _dragPosition = maxDrag;
        _isFinished = true;
      });
      Future.delayed(const Duration(milliseconds: 200), widget.onAction);
    } else {
      _snapAnimation =
          Tween<double>(begin: _dragPosition, end: 0).animate(
            CurvedAnimation(
              parent: _snapController,
              curve: Curves.easeOutCubic,
            ),
          )..addListener(() {
            setState(() {
              _dragPosition = _snapAnimation.value;
            });
          });
      _snapController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const double trackHeight = 64.0;
    const double hPadding = 6.0;
    const double vPadding = 4.0;
    const double activeHeight = trackHeight - (vPadding * 2);

    final Color handleColor = isDark ? Colors.white : theme.colorScheme.primary;

    final Color iconInsideColor = isDark
        ? const Color(0xFF101A32)
        : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag =
            constraints.maxWidth - activeHeight - (hPadding * 2);

        return ClipRRect(
          borderRadius: BorderRadius.circular(trackHeight / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              height: trackHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: hPadding,
                vertical: vPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(trackHeight / 2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Opacity(
                      opacity: (1 - (_dragPosition / maxDrag) * 1.5).clamp(
                        0.0,
                        1.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const ThreeAnimatedArrows(color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                  //draggable button
                  Positioned(
                    left: _dragPosition,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) =>
                            _handleDragUpdate(details, maxDrag),
                        onHorizontalDragEnd: (details) =>
                            _handleDragEnd(details, maxDrag),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: activeHeight,
                          height: activeHeight,
                          decoration: BoxDecoration(
                            color: _isFinished
                                ? Colors.greenAccent
                                : handleColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _isFinished
                                    ? Colors.green.withValues(alpha: 0.7)
                                    : (isDark
                                          ? Colors.black45
                                          : theme.colorScheme.primary
                                                .withValues(alpha: 0.3)),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFinished
                                ? Icons.check_rounded
                                : Icons.arrow_forward_ios_rounded,
                            color: _isFinished
                                ? const Color(0xFF101A32)
                                : iconInsideColor,
                            size: activeHeight * 0.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
