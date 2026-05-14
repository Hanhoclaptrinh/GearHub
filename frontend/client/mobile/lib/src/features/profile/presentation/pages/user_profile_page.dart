import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/src/features/auth/presentation/pages/register_page.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/profile/presentation/widgets/order_status_card.dart';
import 'package:mobile/src/features/profile/presentation/widgets/profile_header.dart';
import 'package:mobile/src/features/profile/presentation/widgets/profile_menu_card.dart';
import 'package:mobile/src/features/profile/presentation/widgets/ultilities_grid.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showErrorSnackBar(context, state.message);
        }
      },
      child: BlocProvider(
        create: (context) => getIt<OrdersCubit>()..fetchMyOrders(status: 'ALL'),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: AppColors.background,
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
                          color: const Color(0xFFFDE047).withValues(alpha: 0.03),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),

                    RefreshIndicator(
                      color: const Color(0xFFFDE047),
                      backgroundColor: const Color(0xFF14141E),
                      strokeWidth: 2,
                      onRefresh: () async {
                        if (isLoggedIn) {
                          await context.read<OrdersCubit>().fetchMyOrders(
                            status: 'ALL',
                          );
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
                                children: [
                                  ProfileHeader(user: user),
                                ],
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

                                ProfileMenuCard(
                                  groupLabel: 'CÀI ĐẶT HỆ THỐNG',
                                  items: [
                                    ProfileMenuItem(
                                      title: 'Chế độ tối',
                                      isToggle: true,
                                      toggleValue: _isDarkMode,
                                      onToggle: (val) {
                                        setState(() => _isDarkMode = val);
                                        HapticFeedback.selectionClick();
                                      },
                                    ),
                                    if (isLoggedIn) ...[
                                      ProfileMenuItem(
                                        title: 'Địa chỉ đã lưu',
                                        onTap: () {},
                                      ),
                                      ProfileMenuItem(
                                        title: 'Phương thức thanh toán',
                                        onTap: () {},
                                      ),
                                    ],
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


  Widget _buildQuietLogout(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Center(
          child: GestureDetector(
            onTap: isLoading
                ? null
                : () => _showQuietLogoutConfirmation(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: isLoading
                  ? const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white24,
                      ),
                    )
                  : Text(
                      'ĐĂNG XUẤT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error.withValues(alpha: 0.8),
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginCTA(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TÙY CHỌN ĐĂNG NHẬP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'MỞ KHÓA TOÀN BỘ TRẢI NGHIỆM',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _buildAuthTile(
                      'ĐĂNG NHẬP',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildAuthTile(
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

  Widget _buildAuthTile(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.6,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  void _showQuietLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A0A0A),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          contentPadding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'XÁC NHẬN ĐĂNG XUẤT',
                style: TextStyle(
                  fontWeight: FontWeight.w200,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Fen chắc chắn muốn kết thúc phiên đăng nhập tuyệt vời này chứ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'HỦY',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.read<AuthCubit>().logout();
                      },
                      child: const Text(
                        'XÁC NHẬN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
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
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(32),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
