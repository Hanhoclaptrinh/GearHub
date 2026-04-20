import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:mobile/src/shared/models/product.dart';
import 'package:mobile/src/features/onboarding/presentation/widgets/three_animated_arrow.dart';

class StickyBottomBar extends StatefulWidget {
  final Product product;

  const StickyBottomBar({super.key, required this.product});

  @override
  State<StickyBottomBar> createState() => _StickyBottomBarState();
}

class _StickyBottomBarState extends State<StickyBottomBar>
    with SingleTickerProviderStateMixin {
  bool _isAdded = false;
  double _dragPosition = 0.0;
  double _sliderWidth = 0.0;
  final double _thumbSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    _buildOrderButton(colorScheme),
                    const SizedBox(width: 10),
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
                    padding: EdgeInsets.only(left: _isAdded ? 0 : 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isAdded ? 'Added to Cart' : 'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _isAdded
                                ? Colors.white
                                : colorScheme.onPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (!_isAdded) ...[
                          const SizedBox(width: 8),
                          ThreeAnimatedArrows(color: colorScheme.onPrimary),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // slide thumb
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

  Widget _buildOrderButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
      },
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: colorScheme.onSurface,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: Text(
            'Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.surface,
            ),
          ),
        ),
      ),
    );
  }
}
