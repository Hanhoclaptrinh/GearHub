import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mobile/src/features/onboarding/presentation/pages/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _zoomController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    //zoom
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    //scale
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.7).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOutBack),
    );

    //pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _runSplashSequence();
    FlutterNativeSplash.remove();
  }

  Future<void> _runSplashSequence() async {
    //zoom in
    await _zoomController.forward();

    //pulse
    _pulseController.repeat(reverse: true);

    //transition to onboarding
    if (mounted) {
      _pulseController.stop();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_zoomController, _pulseController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * _pulseAnimation.value,
              child: Image.asset(
                'assets/logo/logo.png',
                width: screenWidth * 3.8,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}
