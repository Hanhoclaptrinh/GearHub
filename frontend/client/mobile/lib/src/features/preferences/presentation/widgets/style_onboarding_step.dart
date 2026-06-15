import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/src/core/utils/style_options.dart';

class StyleOnboardingStep extends StatefulWidget {
  final Set<String> selectedStyleTags;
  final Function(String) onStyleToggled;

  const StyleOnboardingStep({
    super.key,
    required this.selectedStyleTags,
    required this.onStyleToggled,
  });

  @override
  State<StyleOnboardingStep> createState() => _StyleOnboardingStepState();
}

class _StyleOnboardingStepState extends State<StyleOnboardingStep>
    with SingleTickerProviderStateMixin {
  double _currentPage = 0.0; //current virtual scroll position
  late AnimationController _animationController;
  Animation<double>? _snapAnimation;

  final List<StyleOption> _styles = techStyleOptions;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _styleCount => _styles.length;

  //helper to normalize index/positions for infinite loop dynamically
  double _getDifference(int index) {
    double diff = index - _currentPage;
    double halfCount = _styleCount / 2;
    while (diff < -halfCount) {
      diff += _styleCount;
    }
    while (diff > halfCount) {
      diff -= _styleCount;
    }
    return diff;
  }

  void _animateToPage(int targetPage) {
    double startPage = _currentPage;
    double diff = targetPage - startPage;
    double halfCount = _styleCount / 2;
    while (diff < -halfCount) {
      diff += _styleCount;
    }
    while (diff > halfCount) {
      diff -= _styleCount;
    }
    double endPage = startPage + diff;

    _snapAnimation =
        Tween<double>(begin: startPage, end: endPage).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        )..addListener(() {
          setState(() {
            _currentPage = _snapAnimation!.value;
            //keep internal page normalized
            if (_currentPage < 0) _currentPage += _styleCount;
            if (_currentPage >= _styleCount) _currentPage -= _styleCount;
          });
        });

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<int> renderOrder = List.generate(_styles.length, (index) => index);
    renderOrder.sort((a, b) {
      double diffA = _getDifference(a).abs();
      double diffB = _getDifference(b).abs();
      return diffB.compareTo(diffA); //descending distance
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lựa chọn\nchất riêng',
                style: GoogleFonts.outfit(
                  fontSize: size.width * 0.13,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Định hình cá tính cho góc setup của bạn. Chọn phong cách thiết kế mà bạn ưng ý nhất nhé.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface.withValues(alpha: .5),
                ),
              ),
            ],
          ),
        ),

        //custom ctack-based 3D carousel with drag detection
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (_animationController.isAnimating) {
              _animationController.stop();
            }
            setState(() {
              _currentPage -= details.primaryDelta! / 260.0;
              //keep internal page normalized
              if (_currentPage < 0) _currentPage += _styleCount;
              if (_currentPage >= _styleCount) _currentPage -= _styleCount;
            });
          },
          onHorizontalDragEnd: (details) {
            double velocity = details.primaryVelocity ?? 0;
            int snapPage;
            if (velocity.abs() > 400) {
              snapPage = velocity > 0
                  ? (_currentPage.floor())
                  : (_currentPage.ceil());
            } else {
              snapPage = _currentPage.round();
            }
            _animateToPage(snapPage % _styleCount);
          },
          child: Container(
            color: Colors.transparent,
            height: 480,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: renderOrder.map((index) {
                final style = _styles[index];
                final isSelected = widget.selectedStyleTags.contains(style.tag);

                double diff = _getDifference(index);
                double absDiff = diff.abs();

                //skip rendering completely if cards are too far away
                if (absDiff > 1.8) return const SizedBox.shrink();

                //compute scale: active card is 1.0, side cards are 0.78
                double scale = 1.0 - (absDiff * 0.22).clamp(0.0, 0.45);

                //compute horizontal displacement
                double translationX = diff * 140.0;

                //opacity curve: fade side cards slightly but keep visible
                double opacity = (1.0 - (absDiff * 0.15)).clamp(0.0, 1.0);

                //3D rotation angle
                double rotationY = (diff * 0.2).clamp(-0.4, 0.4);

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) //3D perspective
                    ..translate(translationX, 0.0, 0.0)
                    ..scale(scale)
                    ..rotateY(rotationY),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity,
                    child: SizedBox(
                      width: 270,
                      height: 420,
                      child: GestureDetector(
                        onTap: () {
                          if (absDiff < 0.15) {
                            widget.onStyleToggled(style.tag);
                          } else {
                            _animateToPage(index);
                          }
                        },
                        child: _buildCard(style, isSelected, isDark, theme),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    StyleOption style,
    bool isSelected,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.lerp(style.gradientColors[0], Colors.black, 0.5)!,
                  Color.lerp(style.gradientColors[1], Colors.black, 0.75)!,
                ]
              : [style.gradientColors[0], style.gradientColors[1]],
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? style.gradientColors[0].withValues(alpha: isDark ? 0.45 : 0.3)
                : Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: isSelected ? 24 : 14,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? style.gradientColors[0]
              : Colors.white.withValues(alpha: isDark ? 0.08 : 0.35),
          width: isSelected ? 3.0 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //style image illustration covering the top/middle part
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: isDark ? Colors.black26 : Colors.white12,
                    child: Image.network(
                      style.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? Colors.black54 : Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: isDark ? Colors.white24 : Colors.black26,
                            size: 40,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: isDark ? Colors.black38 : Colors.grey[100],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                //bottom section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 52,
                        child: Text(
                          style.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            height: 1.3,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            //selection indicator checkmark
            Positioned(
              top: 14,
              right: 14,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? style.gradientColors[0]
                      : Colors.black.withValues(alpha: .4),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white70,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
