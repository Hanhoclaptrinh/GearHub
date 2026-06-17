import 'package:flutter/material.dart';

class PressableScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScaleButton({super.key, required this.child, this.onTap});

  @override
  State<PressableScaleButton> createState() => _PressableScaleButtonState();
}

class _PressableScaleButtonState extends State<PressableScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0.0,
    upperBound: 0.035,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _ctrl.forward(),
      onTapCancel: widget.onTap == null ? null : () => _ctrl.reverse(),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _ctrl.reverse();
              widget.onTap?.call();
            },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          return Transform.scale(scale: 1.0 - _ctrl.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
