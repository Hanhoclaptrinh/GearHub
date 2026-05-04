import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/home/presentation/pages/home_page.dart';
import 'package:mobile/src/features/cart/presentation/pages/cart_page.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_state.dart';
import 'package:mobile/src/features/profile/presentation/pages/user_profile_page.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  bool _isBottomBarVisible = true;
  bool get isBottomBarVisible => _isBottomBarVisible;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static Widget _buildPlaceholderPage(String title) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                title[0],
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Coming Soon...',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  void onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _isBottomBarVisible = true; // luon hien khi chuyen tab
    });
    if (index == 1) {
      context.read<CartCubit>().loadCart();
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomePage(),
      CartPage(isNavVisible: _isBottomBarVisible),
      _buildPlaceholderPage('Wishlist'),
      const UserProfilePage(),
    ];

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.read<CartCubit>().syncCart();
        } else if (state is AuthUnauthenticated) {
          if (!_isBottomBarVisible) {
            setState(() => _isBottomBarVisible = true);
          }
          context.read<CartCubit>().loadCart();
        }
      },

      child: Scaffold(
        extendBody: true,
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            // scroll ngang thi khong an/hien bottom bar
            if (notification.metrics.axis != Axis.vertical) return false;

            if (notification.direction == ScrollDirection.reverse) {
              if (_isBottomBarVisible) {
                setState(() => _isBottomBarVisible = false);
              }
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_isBottomBarVisible) {
                setState(() => _isBottomBarVisible = true);
              }
            }
            return true;
          },
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: pages,
          ),
        ),
        bottomNavigationBar: AnimatedSlide(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 2),
          child: CustomBottomNavBar(
            selectedIndex: _selectedIndex,
            onItemSelected: onItemTapped,
          ),
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, padding.bottom + 16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(context, 0, LucideIcons.house, 'Trang chủ'),
                _buildNavItem(context, 1, LucideIcons.shoppingCart, 'Cart'),
                _buildNavItem(context, 2, LucideIcons.heart, 'Wishlist'),
                _buildNavItem(context, 3, LucideIcons.userRound, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = colorScheme.primary;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? accentColor
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                if (index == 1)
                  BlocBuilder<CartCubit, CartState>(
                    builder: (context, state) {
                      int count = 0;
                      if (state.cart != null) {
                        count = state.cart!.items.length;
                      }
                      if (count == 0) return const SizedBox.shrink();
                      return Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4D4D),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: -0.2,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
