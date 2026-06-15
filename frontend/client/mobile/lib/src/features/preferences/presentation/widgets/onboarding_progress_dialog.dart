import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingProgressDialog extends StatefulWidget {
  final Future<void> Function() onSaveAction;
  final VoidCallback onFinish;

  const OnboardingProgressDialog({
    super.key,
    required this.onSaveAction,
    required this.onFinish,
  });

  @override
  State<OnboardingProgressDialog> createState() =>
      _OnboardingProgressDialogState();
}

class _OnboardingProgressDialogState extends State<OnboardingProgressDialog>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  bool _isDone = false;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: 100.0).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        )..addListener(() {
          setState(() {
            _progress = _progressAnimation.value;
          });
        });

    //start progress simulation and the actual save action
    _startSavingProcess();
  }

  Future<void> _startSavingProcess() async {
    //start the animation to progress
    _progressController.forward();

    try {
      //execute the actual repository save method in parallel
      await widget.onSaveAction();

      if (mounted) {
        if (_progressController.value < 1.0) {
          _progressController
              .animateTo(1.0, duration: const Duration(milliseconds: 500))
              .then((_) {
                if (mounted) {
                  setState(() {
                    _isDone = true;
                  });
                }
              });
        } else {
          setState(() {
            _isDone = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: .08)
                    : Colors.black.withValues(alpha: .06),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //circle container
                SizedBox(
                  width: 100,
                  height: 100,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _hasError
                        ? Icon(
                            Icons.error_outline_rounded,
                            key: const ValueKey('error'),
                            color: theme.colorScheme.error,
                            size: 72,
                          )
                        : _isDone
                        ? Container(
                            key: const ValueKey('done'),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: .3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 44,
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CircularProgressIndicator(
                                  value: _progress / 100,
                                  strokeWidth: 8,
                                  strokeCap: StrokeCap.round,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: .1)
                                      : Colors.black.withValues(alpha: .06),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                //percentage text or status
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _hasError
                      ? Text(
                          'Đã xảy ra lỗi',
                          key: const ValueKey('error_txt'),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        )
                      : _isDone
                      ? Text(
                          'Đã xong',
                          key: const ValueKey('done_txt'),
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        )
                      : Text(
                          '${_progress.toInt()}%',
                          key: const ValueKey('percent_txt'),
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                ),

                if (_hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: .6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isDone = false;
                          _progress = 0.0;
                        });
                        _progressController.reset();
                        _startSavingProcess();
                      },
                      child: Text(
                        'Thử lại',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Đóng',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: .6,
                        ),
                      ),
                    ),
                  ),
                ],

                if (_isDone) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); //dismiss dialog
                        widget.onFinish(); //callback to navigate to main screen
                      },
                      child: Text(
                        'Khám phá ngay',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
