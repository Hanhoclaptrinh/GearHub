import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/theme_cubit.dart';
import 'package:mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/src/features/auth/presentation/pages/register_page.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/profile/presentation/widgets/order_status_card.dart';
import 'package:mobile/src/features/profile/presentation/widgets/profile_header.dart';
import 'package:mobile/src/features/profile/presentation/widgets/profile_menu_card.dart';
import 'package:mobile/src/features/profile/presentation/widgets/ultilities_grid.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';
import 'package:mobile/src/features/promotions/presentation/state/my_vouchers_cubit.dart';
import 'package:mobile/src/features/address/presentation/pages/addresses_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'Tiếng Việt';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        if (state is AuthError) {
          _showErrorSnackBar(context, state.message);
        }
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                getIt<OrdersCubit>()..fetchMyOrders(status: 'ALL'),
          ),
          BlocProvider(
            create: (context) => getIt<MyVouchersCubit>()..fetchMyVouchers(),
          ),
        ],
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                final isLoggedIn = state is AuthAuthenticated;

                return Stack(
                  children: [
                    Positioned(
                      top: -100,
                      right: -100,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.secondary.withValues(alpha: 0.03),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),

                    RefreshIndicator(
                      color: cs.secondary,
                      backgroundColor: cs.surfaceContainerHighest,
                      strokeWidth: 2,
                      onRefresh: () async {
                        if (isLoggedIn) {
                          await Future.wait([
                            context.read<OrdersCubit>().fetchMyOrders(
                              status: 'ALL',
                            ),
                            context.read<MyVouchersCubit>().fetchMyVouchers(),
                          ]);
                        }
                      },
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: SafeArea(
                              bottom: false,
                              child: Column(
                                children: [ProfileHeader(user: user)],
                              ),
                            ),
                          ),

                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                if (isLoggedIn) ...[
                                  const OrderStatusCard(),
                                  const SizedBox(height: 48),
                                  const UtilitiesGrid(),
                                ] else ...[
                                  const SizedBox(height: 40),
                                  _buildLoginCTA(context),
                                ],

                                const SizedBox(height: 48),
                                _buildThemeSelector(context),

                                const SizedBox(height: 24),

                                ProfileMenuCard(
                                  groupLabel: 'CÀI ĐẶT HỆ THỐNG',
                                  items: [
                                    if (isLoggedIn) ...[
                                      ProfileMenuItem(
                                        title: 'Địa chỉ đã lưu',
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AddressesPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      ProfileMenuItem(
                                        title: 'Phương thức thanh toán',
                                        onTap: () {},
                                      ),
                                    ],
                                    ProfileMenuItem(
                                      title: 'Ngôn ngữ',
                                      badge: _selectedLanguage,
                                      onTap: () => _showLanguagePopup(context),
                                    ),
                                    ProfileMenuItem(
                                      title: 'Thông báo',
                                      isToggle: true,
                                      toggleValue: _notificationsEnabled,
                                      onToggle: (val) {
                                        setState(() {
                                          _notificationsEnabled = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 60),

                                if (isLoggedIn) _buildQuietLogout(context),

                                const SizedBox(height: 100),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguagePopup(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: cs.outlineVariant, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageOption(
                    context: dialogCtx,
                    label: 'Tiếng Việt',
                    isSelected: _selectedLanguage == 'Tiếng Việt',
                    onTap: () {
                      setState(() => _selectedLanguage = 'Tiếng Việt');
                      Navigator.pop(dialogCtx);
                    },
                  ),
                  Divider(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildLanguageOption(
                    context: dialogCtx,
                    label: 'English',
                    isSelected: _selectedLanguage == 'English',
                    onTap: () {
                      setState(() => _selectedLanguage = 'English');
                      Navigator.pop(dialogCtx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.translate_rounded,
                size: 18,
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, currentMode) {
        final themeOptions = [
          {
            'mode': ThemeMode.system,
            'label': 'Hệ thống',
            'icon': Icons.settings_suggest_outlined,
          },
          {
            'mode': ThemeMode.light,
            'label': 'Sáng',
            'icon': Icons.light_mode_outlined,
          },
          {
            'mode': ThemeMode.dark,
            'label': 'Tối',
            'icon': Icons.dark_mode_outlined,
          },
        ];
        final selectedIndex = themeOptions.indexWhere(
          (o) => o['mode'] == currentMode,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'GIAO DIỆN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface.withValues(alpha: 0.2),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.onSurface.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth - 12;
                  final itemWidth = totalWidth / themeOptions.length;

                  return Padding(
                    padding: const EdgeInsets.all(6),
                    child: Stack(
                      children: [
                        if (selectedIndex != -1)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            left: selectedIndex * itemWidth,
                            width: itemWidth,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Row(
                          children: themeOptions.map((option) {
                            final mode = option['mode'] as ThemeMode;
                            final label = option['label'] as String;
                            final icon = option['icon'] as IconData;
                            final selected = mode == currentMode;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  if (mode == ThemeMode.system) {
                                    context.read<ThemeCubit>().useSystemTheme();
                                  } else if (mode == ThemeMode.light) {
                                    context.read<ThemeCubit>().useLightTheme();
                                  } else {
                                    context.read<ThemeCubit>().useDarkTheme();
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 18,
                                        color: selected
                                            ? cs.onPrimary
                                            : cs.onSurface.withValues(
                                                alpha: 0.3,
                                              ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: selected
                                              ? FontWeight.w900
                                              : FontWeight.w500,
                                          color: selected
                                              ? cs.onPrimary
                                              : cs.onSurface.withValues(
                                                  alpha: 0.3,
                                                ),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuietLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading
                ? null
                : () => _showQuietLogoutConfirmation(context),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 56,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: danger.withValues(alpha: isDark ? 0.11 : 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: danger.withValues(alpha: isDark ? 0.24 : 0.16),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: danger.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Đang đăng xuất',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: danger.withValues(alpha: 0.82),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: danger.withValues(alpha: 0.86),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: danger.withValues(alpha: 0.88),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginCTA(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TÙY CHỌN ĐĂNG NHẬP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.05),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'MỞ KHÓA TOÀN BỘ TRẢI NGHIỆM',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w200,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _buildAuthTile(
                      context,
                      'ĐĂNG NHẬP',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildAuthTile(
                      context,
                      'THAM GIA',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthTile(
    BuildContext context,
    String label, {
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.05),
            width: 0.6,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  void _showQuietLogoutConfirmation(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.58 : 0.34),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: isDark ? 0.36 : 0.7),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.12),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: danger.withValues(alpha: isDark ? 0.14 : 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: danger.withValues(alpha: isDark ? 0.24 : 0.14),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 22,
                    color: danger.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Đăng xuất khỏi GearHub?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: cs.onSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bạn sẽ cần đăng nhập lại để tiếp tục theo dõi đơn hàng, voucher và các tiện ích cá nhân.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.56),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: cs.onSurface.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          child: Text(
                            'Ở lại',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.72),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            context.read<AuthCubit>().logout();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: danger,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Đăng xuất',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(32),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
