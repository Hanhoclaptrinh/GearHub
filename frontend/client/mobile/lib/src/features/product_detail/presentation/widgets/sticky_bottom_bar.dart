import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'dart:async';
import 'package:mobile/src/features/home/domain/models/product.dart';

class StickyBottomBar extends StatefulWidget {
  final Product product;

  const StickyBottomBar({super.key, required this.product});

  @override
  State<StickyBottomBar> createState() => _StickyBottomBarState();
}

class _StickyBottomBarState extends State<StickyBottomBar>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  final int _maxQuantity = 10;

  // timer cho spam tang giam
  Timer? _timer;

  bool _isAdded = false;
  double _dragPosition = 0.0;
  double _sliderWidth = 0.0;
  final double _thumbSize = 56.0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _incrementQuantity() {
    if (_quantity < _maxQuantity) {
      HapticFeedback.lightImpact();
      setState(() => _quantity++);
    } else {
      _stopContinuous();
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      HapticFeedback.lightImpact();
      setState(() => _quantity--);
    } else {
      _stopContinuous();
    }
  }

  void _startContinuous(VoidCallback action) {
    action();
    // timer 150ms
    // nhan giu button de tang hoac giam so luong lien tuc
    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) => action());
  }

  void _stopContinuous() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _buildQuantitySelector(colorScheme),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSlideToAddButton(colorScheme)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(ColorScheme colorScheme) {
    bool isMin = _quantity <= 1;
    bool isMax = _quantity >= _maxQuantity;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            // chua min thi tiep tuc giam
            onTap: isMin ? null : _decrementQuantity,
            // nhan giu lau thi giam lien tuc moi 150ms
            onLongPressStart: isMin
                ? null
                : (_) => _startContinuous(_decrementQuantity),
            onLongPressEnd: (_) => _stopContinuous(),
            onLongPressCancel: _stopContinuous,
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isMin ? 0.3 : 1.0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMin
                      ? Colors.transparent
                      : colorScheme.onSurface.withValues(alpha: 0.05),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.minus,
                    color: colorScheme.onSurface,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(
            width: 32,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Text(
                '$_quantity',
                key: ValueKey<int>(_quantity),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),

          GestureDetector(
            // chua max thi tiep tuc tang
            onTap: isMax ? null : _incrementQuantity,
            // nhan giu lau thi tang lien tuc moi 150ms
            onLongPressStart: isMax
                ? null
                : (_) => _startContinuous(_incrementQuantity),
            onLongPressEnd: (_) => _stopContinuous(),
            onLongPressCancel: _stopContinuous,
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isMax ? 0.3 : 1.0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMax
                      ? Colors.transparent
                      : colorScheme.onSurface.withValues(alpha: 0.05),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.plus,
                    color: colorScheme.onSurface,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideToAddButton(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _sliderWidth = constraints.maxWidth;
        final maxDragPosition = _sliderWidth - _thumbSize - 8;

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _isAdded
                  ? const Color(0xFF34C759)
                  : colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              AnimatedContainer(
                duration: _dragPosition == 0
                    ? const Duration(milliseconds: 300)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                width: _isAdded ? _sliderWidth : _dragPosition + _thumbSize + 8,
                height: 64,
                decoration: BoxDecoration(
                  color: _isAdded
                      ? const Color(0xFF34C759)
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(32),
                ),
              ),

              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    key: ValueKey(_isAdded),
                    padding: EdgeInsets.only(left: _isAdded ? 0 : 48),
                    child: Text(
                      _isAdded ? 'Added to Cart' : 'Slide to Add',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _isAdded ? Colors.white : colorScheme.onPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              // slide thumb
              // neu chua duoc add thi hien thi slide thumb trong khi truot
              if (!_isAdded)
                AnimatedPositioned(
                  duration: _dragPosition == 0
                      ? const Duration(milliseconds: 400)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  left: 4 + _dragPosition,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragPosition += details.delta.dx;
                        if (_dragPosition < 0) _dragPosition = 0;
                        if (_dragPosition > maxDragPosition) {
                          _dragPosition = maxDragPosition;
                        }
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_dragPosition > maxDragPosition * 0.75) {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          _dragPosition = maxDragPosition;
                          _isAdded = true;
                        });

                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              _isAdded = false;
                              _dragPosition = 0.0;
                            });
                          }
                        });
                      } else {
                        setState(() {
                          _dragPosition = 0.0;
                        });
                        HapticFeedback.lightImpact();
                      }
                    },
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colorScheme.primary,
                        size: 26,
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
