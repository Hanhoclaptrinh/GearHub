import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/home/presentation/pages/home_page.dart';
import 'package:mobile/src/features/cart/presentation/pages/cart_page.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_state.dart';
import 'package:mobile/src/features/profile/presentation/pages/user_profile_page.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/explore/presentation/pages/explore_page.dart';
import 'package:mobile/src/features/promotions/presentation/pages/promotions_page.dart';

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

  void onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _isBottomBarVisible = true;
    });
    if (index == 2) {
      // cart page is at index 2
      context.read<CartCubit>().loadCart();
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomePage(),
      const ExplorePage(),
      CartPage(isNavVisible: _isBottomBarVisible),
      const PromotionsPage(),
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
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutQuart,
          offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 1.5),
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

  static const _items = [
    (icon: LucideIcons.house, label: 'Trang chủ'),
    (icon: LucideIcons.search, label: 'Shop'),
    (icon: LucideIcons.shoppingCart, label: 'Giỏ hàng'),
    (icon: LucideIcons.shieldCheck, label: 'Ưu đãi'),
    (icon: LucideIcons.userRound, label: 'Tôi'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF050505).withValues(alpha: 0.72),
            const Color(0xFF050505),
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(28, 8, 28, bottomPadding + 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          _items.length,
          (i) => _ArchitecturalNavItem(
            index: i,
            icon: _items[i].icon,
            label: _items[i].label,
            isSelected: selectedIndex == i,
            isVault: i == 2,
            onTap: () => onItemSelected(i),
          ),
        ),
      ),
    );
  }
}

class _ArchitecturalNavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isVault;
  final VoidCallback onTap;

  const _ArchitecturalNavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isVault = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconLayer(),
            const SizedBox(height: 8),
            _buildLabelLayer(),
            const SizedBox(height: 4),
            _buildIndicatorLayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconLayer() {
    Widget iconWidget = Icon(
      icon,
      size: 20,
      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.22),
    );

    if (!isVault) return iconWidget;

    // cart badge
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final count = state.cart?.items.length ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget,
            if (count > 0)
              Positioned(
                top: -2,
                right: -4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLabelLayer() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isSelected ? 0.5 : 0.0,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildIndicatorLayer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: isSelected ? 3 : 0,
      height: 3,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }
}
