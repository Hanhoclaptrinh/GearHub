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
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF0A0A0F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: BlocProvider(
        create: (context) => getIt<OrdersCubit>()..fetchMyOrders(status: 'ALL'),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final user = state is AuthAuthenticated ? state.user : null;
              final isLoggedIn = state is AuthAuthenticated;

              return RefreshIndicator(
                color: const Color(0xFF3B82F6),
                onRefresh: () async {
                  if (isLoggedIn) {
                    await context.read<OrdersCubit>().fetchMyOrders(status: 'ALL');
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                      child: Column(
                        children: [
                          ProfileHeader(user: user),
                          if (isLoggedIn) ...[
                            const SizedBox(height: 24),
                            const OrderStatusCard(),
                            const SizedBox(height: 24),
                            const UtilitiesGrid(),
                          ] else ...[
                            const SizedBox(height: 48),
                            _buildLoginCTA(context),
                          ],
                          const SizedBox(height: 24),
                          ProfileMenuCard(
                            groupLabel: 'Tùy chỉnh',
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
                                  title: 'Danh sách địa chỉ',
                                  icon: LucideIcons.mapPin,
                                  onTap: () {},
                                ),
                                ProfileMenuItem(
                                  title: 'Phương thức thanh toán',
                                  icon: LucideIcons.creditCard,
                                  onTap: () {},
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (isLoggedIn) _buildLogoutButton(),
                          const SizedBox(height: 24),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  _showLogoutConfirmation(context);
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D4D).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF4D4D),
                      ),
                    ),
                  )
                : const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF4D4D),
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoginCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.userRound, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          const Text(
            'Mở khóa đầy đủ tính năng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A0A0F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đăng nhập để theo dõi đơn hàng, lưu danh sách yêu thích và quản lý tài khoản của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    // navigate to login
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A0A0F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A0A0F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'Đăng ký',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        content: const Text(
          'Xác nhận đăng xuất?',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().logout();
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Color(0xFFFF4D4D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text(
          'GearHub v1.0.0',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFC0C0C0),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
