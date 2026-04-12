import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/src/features/home/presentation/pages/home_page.dart';
import 'package:mobile/src/features/onboarding/domain/models/onboarding_item.dart';
import 'package:mobile/src/features/onboarding/presentation/widgets/onboarding_glass_card.dart';
import 'package:mobile/src/features/onboarding/presentation/widgets/onboarding_indicator.dart';
import 'package:mobile/src/features/onboarding/presentation/widgets/slide_to_action_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _skip() {
    _pageController.animateToPage(
      OnboardingData.items.length - 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuad,
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final bool isLastPage = _currentIndex == OnboardingData.items.length - 1;
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // main
          PageView.builder(
            controller: _pageController,
            itemCount: OnboardingData.items.length,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = OnboardingData.items[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.1),
                    OnboardingGlassCard(
                      imageUrl: item.imageUrl,
                      height: size.height * 0.45,
                    ),
                    SizedBox(height: size.height * 0.05),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: size.width * 0.08,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.05,
                      ),
                      child: Text(
                        item.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: size.width * 0.04,
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.15),
                  ],
                ),
              );
            },
          ),

          // top bar
          // logo and skip button
          Positioned(
            top: padding.top + size.height * 0.02,
            left: size.width * 0.06,
            right: size.width * 0.06,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Hero(
                  tag: 'app_logo',
                  flightShuttleBuilder:
                      (
                        flightContext,
                        animation,
                        flightDirection,
                        fromHeroContext,
                        toHeroContext,
                      ) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final logoSize = Tween<double>(
                              begin: 150,
                              end: 48,
                            ).evaluate(animation);
                            return SvgPicture.asset(
                              'assets/logo/logo.svg',
                              width: logoSize,
                              height: logoSize,
                            );
                          },
                        );
                      },
                  child: SvgPicture.asset(
                    'assets/logo/logo.svg',
                    width: 48,
                    height: 48,
                  ),
                ),
                AnimatedOpacity(
                  opacity: isLastPage ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: IgnorePointer(
                    ignoring: isLastPage,
                    child: TextButton(
                      onPressed: _skip,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip',
                            style: TextStyle(
                              color: textColor,
                              fontSize: size.width * 0.04,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: size.width * 0.05,
                            color: textColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // bottom indicators
          Positioned(
            bottom: padding.bottom + size.height * 0.15,
            left: 0,
            right: 0,
            child: OnboardingIndicator(
              count: OnboardingData.items.length,
              currentIndex: _currentIndex,
            ),
          ),

          // sliding button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            bottom: isLastPage
                ? padding.bottom + size.height * 0.04
                : -size.height * 0.15,
            left: size.width * 0.06,
            right: size.width * 0.06,
            child: SlideToActionButton(onAction: _navigateToHome),
          ),
        ],
      ),
    );
  }
}
