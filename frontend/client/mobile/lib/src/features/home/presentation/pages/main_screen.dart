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

const _surface = Color(0xFF14141E);

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
    if (index == 4) {
      context.read<CartCubit>().loadCart();
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomePage(),
      const ExplorePage(),
      const PromotionsPage(),
      const UserProfilePage(),
      CartPage(isNavVisible: _isBottomBarVisible),
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
          duration: const Duration(milliseconds: 600),
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

  static const _mainItems = [
    (icon: LucideIcons.house, label: 'Home'),
    (icon: LucideIcons.search, label: 'Explore'),
    (icon: LucideIcons.shieldCheck, label: 'Offers'),
    (icon: LucideIcons.userRound, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isCartSelected = selectedIndex == 4;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _GlassContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _mainItems.length,
                  (i) => _NavItem(
                    index: i,
                    icon: _mainItems[i].icon,
                    label: _mainItems[i].label,
                    isSelected: selectedIndex == i,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onItemSelected(i);
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            borderRadius: BorderRadius.circular(34),
            child: _NavItem(
              index: 4,
              icon: LucideIcons.shoppingCart,
              label: 'Cart',
              isSelected: isCartSelected,
              isCart: true,
              onTap: () {
                HapticFeedback.mediumImpact();
                onItemSelected(4);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const _GlassContainer({required this.child, this.padding, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(32);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 68,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.85),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCart;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCart = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            if (isSelected && !isCart)
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    Widget iconWidget = Icon(
      icon,
      size: 22,
      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
    );

    if (!isCart) return iconWidget;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final count = state.cart?.items.length ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget,
            if (count > 0)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
