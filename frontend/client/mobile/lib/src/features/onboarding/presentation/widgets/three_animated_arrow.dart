import 'package:flutter/material.dart';

class ThreeAnimatedArrows extends StatefulWidget {
  final Color color;
  final bool isLeft;

  const ThreeAnimatedArrows({
    super.key,
    required this.color,
    this.isLeft = false,
  });

  @override
  State<ThreeAnimatedArrows> createState() => _ThreeAnimatedArrowsState();
}

class _ThreeAnimatedArrowsState extends State<ThreeAnimatedArrows>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(); //inf loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (idx) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            //calculate delay: if isLeft, wave should travel right-to-left (idx 2 -> 0)
            final double delay = widget.isLeft ? (2 - idx) * 0.2 : idx * 0.2;
            double opacity = (_controller.value - delay).clamp(0.0, 1.0);
            //fade effect
            if (opacity > 0.5) opacity = 1.0 - opacity;
            opacity = (opacity * 2).clamp(0.2, 1.0);

            return Container(
              width: 12,
              alignment: widget.isLeft
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Icon(
                widget.isLeft
                    ? Icons.arrow_back_ios_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: widget.color.withValues(alpha: opacity),
                size: 20,
              ),
            );
          },
        );
      }),
    );
  }
}
