import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/src/core/utils/use_case_options.dart';

class UseCaseOnboardingStep extends StatefulWidget {
  final Set<String> selectedUseCases;
  final ValueChanged<String> onUseCaseToggled;

  const UseCaseOnboardingStep({
    super.key,
    required this.selectedUseCases,
    required this.onUseCaseToggled,
  });

  @override
  State<UseCaseOnboardingStep> createState() => _UseCaseOnboardingStepState();
}

class _UseCaseOnboardingStepState extends State<UseCaseOnboardingStep> {
  //trạng thái các giá trị hiển thị trên Radar Chart
  late List<double> _radarValues;

  @override
  void initState() {
    super.initState();
    _updateRadarValues();
  }

  @override
  void didUpdateWidget(covariant UseCaseOnboardingStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateRadarValues();
  }

  //cập nhật giá trị hiển thị trên biểu đồ dựa vào dữ liệu thực tế được chọn từ widget cha
  void _updateRadarValues() {
    _radarValues = List.generate(useCaseOptions.length, (index) {
      final option = useCaseOptions[index];
      //nếu được chọn thì đỉnh kéo căng hết cỡ 1.0, nếu không thì thu lại về 0.2
      return widget.selectedUseCases.contains(option.tag) ? 1.0 : 0.2;
    });
  }

  void _handleTapOption(int index) {
    HapticFeedback.lightImpact();
    final option = useCaseOptions[index];
    widget.onUseCaseToggled(option.tag);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;
    //kích thước thực tế của chart
    final chartSize = math.min(size.width * 0.58, 220.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mục đích sử dụng',
          style: GoogleFonts.outfit(
            fontSize: size.width * 0.13,
            fontWeight: FontWeight.w500,
            height: 1.15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Chọn các nhu cầu của bạn để GearHub tự động gợi ý sản phẩm phù hợp bạn nhé.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: .5),
          ),
        ),
        const SizedBox(height: 24),

        //Radar Chart tự động thay đổi theo các nút chọn bên dưới
        Center(
          child: SizedBox(
            width: chartSize + 50,
            height: chartSize + 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<List<double>>(
                  tween: DoubleListTween(
                    begin: _radarValues,
                    end: _radarValues,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, animatedValues, child) {
                    return CustomPaint(
                      size: Size(chartSize, chartSize),
                      painter: RadarChartPainter(
                        values: animatedValues,
                        options: useCaseOptions,
                        isDark: isDark,
                        primaryColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),

                ...List.generate(useCaseOptions.length, (index) {
                  final angle =
                      (index * 2 * math.pi / useCaseOptions.length) -
                      math.pi / 2;
                  final radius = chartSize / 2;

                  final labelDistance = radius + 14;
                  final labelX = labelDistance * math.cos(angle);
                  final labelY = labelDistance * math.sin(angle);

                  final option = useCaseOptions[index];
                  final isSelected = widget.selectedUseCases.contains(
                    option.tag,
                  );

                  return Positioned(
                    left: labelX + (chartSize / 2) + 25 - 15,
                    top: labelY + (chartSize / 2) + 25 - 15,
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(
                        child: Icon(
                          option.icon,
                          color: isSelected
                              ? option.gradientColors[0]
                              : (isDark ? Colors.white30 : Colors.black38),
                          size: 16,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: useCaseOptions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final option = useCaseOptions[index];
            final isSelected = widget.selectedUseCases.contains(option.tag);

            return GestureDetector(
              onTap: () => _handleTapOption(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isSelected
                      ? (isDark
                            ? Colors.white.withValues(alpha: .05)
                            : Colors.black.withValues(alpha: .03))
                      : (isDark
                            ? Colors.white.withValues(alpha: .015)
                            : Colors.black.withValues(alpha: .01)),
                  border: Border.all(
                    color: isSelected
                        ? option.gradientColors[0].withValues(alpha: .35)
                        : (isDark
                              ? Colors.white.withValues(alpha: .06)
                              : Colors.black.withValues(alpha: .06)),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? option.gradientColors[0].withValues(alpha: .12)
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: .04)),
                      ),
                      child: Icon(
                        option.icon,
                        color: isSelected
                            ? option.gradientColors[0]
                            : (isDark ? Colors.white54 : Colors.black54),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.description,
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              color: isDark ? Colors.white38 : Colors.black45,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? option.gradientColors[0]
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.white24 : Colors.black26),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 13,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<UseCaseOption> options;
  final bool isDark;
  final Color primaryColor;

  RadarChartPainter({
    required this.values,
    required this.options,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final int stepCount = values.length;

    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: .08)
          : Colors.black.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: .05)
          : Colors.black.withValues(alpha: .05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    //hình đa giác đồng tâm - 3 vòng lồng nhau
    //biến đổi phù hợp số lượng mục đích sử dụng
    //eg: 5 - ngũ giác đều, 8 - bát giác đều, ...
    for (int i = 1; i <= 3; i++) {
      final currentRadius = radius * (i / 3);
      final path = Path();
      for (int j = 0; j < stepCount; j++) {
        final angle = (j * 2 * math.pi / stepCount) - math.pi / 2;
        final x = center.dx + currentRadius * math.cos(angle);
        final y = center.dy + currentRadius * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    //các trục hướng tâm
    for (int i = 0; i < stepCount; i++) {
      final angle = (i * 2 * math.pi / stepCount) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    //đa giác phù vùng chọn của người dùng
    final fillPath = Path();
    for (int i = 0; i < stepCount; i++) {
      final angle = (i * 2 * math.pi / stepCount) - math.pi / 2;
      final currentRadius = radius * values[i];
      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);
      if (i == 0) {
        fillPath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
      }
    }
    fillPath.close();

    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: .28),
          primaryColor.withValues(alpha: .08),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    //viền da giác
    final borderPaint = Paint()
      ..color = primaryColor.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(fillPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.isDark != isDark;
  }
}

class DoubleListTween extends Tween<List<double>> {
  DoubleListTween({super.begin, super.end});

  @override
  List<double> lerp(double t) {
    final start = begin ?? [];
    final finish = end ?? [];
    final count = math.max(start.length, finish.length);

    return List.generate(count, (i) {
      final s = i < start.length ? start[i] : 0.0;
      final f = i < finish.length ? finish[i] : 0.0;
      return s + (f - s) * t;
    });
  }
}
