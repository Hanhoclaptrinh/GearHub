import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
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
    const bg = Color(0xFF07070A);
    const textMid = Color(0xFF9191A8);

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
            backgroundColor: bg,
            body: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                final isLoggedIn = state is AuthAuthenticated;

                return RefreshIndicator(
                  color: const Color(0xFF3B82F6),
                  backgroundColor: const Color(0xFF0F0F1A),
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
                          child: Column(children: [ProfileHeader(user: user)]),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (isLoggedIn) ...[
                              const OrderStatusCard(),
                              const SizedBox(height: 32),
                              const UtilitiesGrid(),
                            ] else ...[
                              const SizedBox(height: 24),
                              _buildLoginCTA(context),
                            ],

                            const SizedBox(height: 24),

                            ProfileMenuCard(
                              groupLabel: 'CÀI ĐẶT HỆ THỐNG',
                              items: [
                                ProfileMenuItem(
                                  title: 'Chế độ tối',
                                  icon: LucideIcons.moon,
                                  isToggle: true,
                                  toggleValue: _isDarkMode,
                                  onToggle: (val) {
                                    setState(() => _isDarkMode = val);
                                    HapticFeedback.selectionClick();
                                  },
                                ),
                                if (isLoggedIn) ...[
                                  ProfileMenuItem(
                                    title: 'Sổ địa chỉ',
                                    icon: LucideIcons.mapPin,
                                    onTap: () {},
                                  ),
                                  ProfileMenuItem(
                                    title: 'Thanh toán',
                                    icon: LucideIcons.creditCard,
                                    onTap: () {},
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 32),

                            if (isLoggedIn) _buildLogoutButton(context),

                            const SizedBox(height: 40),
                            _buildFooter(textMid),
                            const SizedBox(height: 32),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return GestureDetector(
          onTap: isLoading ? null : () => _showLogoutConfirmation(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.1),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF4D4D),
                    ),
                  )
                : const Text(
                    'ĐĂNG XUẤT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF4D4D),
                      letterSpacing: 2,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoginCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.userRound,
              size: 32,
              color: Color(0xFF4A4A62),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'MỞ KHÓA ĐẶC QUYỀN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Đăng nhập để trải nghiệm hệ sinh thái GearHub Premium fen nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9191A8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginPage())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'ĐĂNG NHẬP',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'ĐĂNG KÝ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'ĐĂNG XUẤT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        content: const Text(
          'Xác nhận kết thúc phiên đăng nhập của fen?',
          style: TextStyle(color: Color(0xFF9191A8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'HỦY',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().logout();
            },
            child: const Text(
              'ĐĂNG XUẤT',
              style: TextStyle(
                color: Color(0xFFFF4D4D),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color textMid) {
    return Column(
      children: [
        const Text(
          'GEARHUB PREMIUM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'VERSION 2.0.0 "PRESTIGE"',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: textMid.withValues(alpha: 0.4),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4D4D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
