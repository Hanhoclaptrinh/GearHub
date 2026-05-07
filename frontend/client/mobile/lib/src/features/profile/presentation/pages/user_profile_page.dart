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

const _bg = Color(0xFF0A0A10);
const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _indigo = Color(0xFF6366F1);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

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
              backgroundColor: _bg,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
      },
      child: BlocProvider(
        create: (context) => getIt<OrdersCubit>()..fetchMyOrders(status: 'ALL'),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: _bg,
            body: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                final isLoggedIn = state is AuthAuthenticated;

                return RefreshIndicator(
                  color: _indigo,
                  backgroundColor: _surface,
                  onRefresh: () async {
                    if (isLoggedIn) {
                      await context.read<OrdersCubit>().fetchMyOrders(status: 'ALL');
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.2),
                width: 1.5,
              ),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C28),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.userRound, size: 40, color: _textLow),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mở khóa đặc quyền',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textHigh,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Đăng nhập để theo dõi đơn hàng, quản lý\ntài khoản và nhận ưu đãi riêng fen nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _textLow,
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textHigh,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    side: const BorderSide(color: _border),
                  ),
                  child: const Text(
                    'Đăng ký',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: _border),
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: _textHigh,
          ),
        ),
        content: const Text(
          'Xác nhận đăng xuất khỏi GearHub?',
          style: TextStyle(color: _textMid, fontSize: 15),
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
          'GearHub Premium v1.0.0',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _textLow,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
