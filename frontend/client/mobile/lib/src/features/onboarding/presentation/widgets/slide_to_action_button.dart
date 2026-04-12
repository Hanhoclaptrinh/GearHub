import 'package:flutter/material.dart';

class SlideToActionButton extends StatefulWidget {
  final VoidCallback onAction;
  final String text;

  const SlideToActionButton({
    super.key,
    required this.onAction,
    this.text = 'Get Started',
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
    const double trackHeight = 64.0;
    const double hPadding = 6.0;
    const double vPadding = 4.0;
    final double activeHeight = trackHeight - (vPadding * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag =
            constraints.maxWidth - activeHeight - (hPadding * 2);

        return Container(
          width: double.infinity,
          height: trackHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: hPadding,
            vertical: vPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(trackHeight / 2),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.double_arrow_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // draggable button
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
                        color: _isFinished ? Colors.greenAccent : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _isFinished
                                ? Colors.green.withOpacity(0.4)
                                : Colors.black26,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFinished
                            ? Icons.check_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        color: const Color(0xFF101A32),
                        size: activeHeight * 0.55,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
