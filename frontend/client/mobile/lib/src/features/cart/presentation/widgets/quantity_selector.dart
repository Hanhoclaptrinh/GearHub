import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFFDE047);
const _accentSoft = Color(0x1AFDE047);
const _textHigh = Colors.white;
const _textLow = Color(0xFF475569);

class QuantitySelector extends StatefulWidget {
  final int quantity;
  final int? maxQuantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelector({
    super.key,
    required this.quantity,
    this.maxQuantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer(VoidCallback action) {
    _timer?.cancel();
    action();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      action();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: LucideIcons.minus,
            onPressed: widget.onDecrement,
            enabled: widget.quantity > 1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '${widget.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: _textHigh,
              ),
            ),
          ),
          _buildButton(
            icon: LucideIcons.plus,
            onPressed: widget.onIncrement,
            enabled:
                widget.maxQuantity == null ||
                widget.quantity < widget.maxQuantity!,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return GestureDetector(
      onTapDown: (details) {
        if (enabled) {
          _onTapDown(details);
          _startTimer(() {
            HapticFeedback.lightImpact();
            onPressed();
          });
        }
      },
      onTapUp: (details) {
        _onTapUp(details);
        _stopTimer();
      },
      onTapCancel: () {
        _onTapCancel();
        _stopTimer();
      },
      onLongPress: () {},
      onLongPressEnd: (_) => _stopTimer(),
      onLongPressCancel: () => _stopTimer(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: enabled ? _accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: enabled
                ? Border.all(color: _accent.withValues(alpha: 0.2), width: 0.5)
                : null,
          ),
          child: Icon(icon, size: 14, color: enabled ? _accent : _textLow),
        ),
      ),
    );
  }
}
