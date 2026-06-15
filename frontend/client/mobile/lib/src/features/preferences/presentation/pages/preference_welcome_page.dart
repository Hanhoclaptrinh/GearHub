import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/home/presentation/pages/main_screen.dart';
import 'package:mobile/src/features/preferences/presentation/pages/preference_onboarding_page.dart';

class PreferenceWelcomePage extends StatefulWidget {
  const PreferenceWelcomePage({super.key});

  @override
  State<PreferenceWelcomePage> createState() => _PreferenceWelcomePageState();
}

class _PreferenceWelcomePageState extends State<PreferenceWelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  //animation cho khối text - left to right
  late Animation<Offset> _leftSlideAnimation;

  //aniamtion cho khối màu - right to left
  late Animation<Offset> _rightSlideAnimation;

  //fade animation
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _leftSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.8, 0.0),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _rightSlideAnimation = Tween<Offset>(
      begin: const Offset(0.8, 0.0),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    //palette
    final purpleColor = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF4F46E5);
    final pinkColor = isDark
        ? const Color(0xFFF472B6)
        : const Color(0xFFEC4899);
    final yellowColor = isDark
        ? const Color(0xFFFDE047)
        : const Color(0xFFEAB308);
    final textColor = theme.colorScheme.onSurface;

    final textStyle = GoogleFonts.outfit(
      fontSize: size.width * 0.15,
      fontWeight: FontWeight.w500,
      color: textColor,
      height: 1.1,
      letterSpacing: -1.0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 4),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SlideTransition(
                            position: _leftSlideAnimation,
                            child: Text('TẠO', style: textStyle),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SlideTransition(
                              position: _rightSlideAnimation,
                              child: Container(
                                height: size.width * 0.10,
                                decoration: BoxDecoration(
                                  color: purpleColor,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.02),

                      Row(
                        children: [
                          SlideTransition(
                            position: _leftSlideAnimation,
                            child: Text('MÀU SẮC', style: textStyle),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SlideTransition(
                              position: _rightSlideAnimation,
                              child: Container(
                                height: size.width * 0.10,
                                decoration: BoxDecoration(
                                  color: pinkColor,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.02),

                      SlideTransition(
                        position: _leftSlideAnimation,
                        child: Text('RIÊNG', style: textStyle),
                      ),
                      SizedBox(height: size.height * 0.02),

                      Row(
                        children: [
                          SlideTransition(
                            position: _leftSlideAnimation,
                            child: Text('CỦA BẠN', style: textStyle),
                          ),
                          const SizedBox(width: 16),
                          SlideTransition(
                            position: _rightSlideAnimation,
                            child: Container(
                              width: size.width * 0.10,
                              height: size.width * 0.10,
                              decoration: BoxDecoration(
                                color: yellowColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      SlideTransition(
                        position: _leftSlideAnimation,
                        child: Material(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(100),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PreferenceOnboardingPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.12,
                                vertical: 18,
                              ),
                              child: Text(
                                'Thiết lập',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),

                      Material(
                        color: Colors.transparent,
                        shape: CircleBorder(
                          side: BorderSide(
                            color: textColor.withValues(alpha: .3),
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final prefs = getIt<SharedPreferences>();
                            await prefs.setBool(
                              'pref_onboarding_processed',
                              true,
                            );
                            if (mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(),
                                ),
                              );
                            }
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 58,
                            height: 58,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.arrow_forward,
                              color: textColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
