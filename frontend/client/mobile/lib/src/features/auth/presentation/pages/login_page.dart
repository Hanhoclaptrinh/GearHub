import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/core/utils/device_utils.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import '../widgets/social_login_button.dart';
import '../widgets/auth_primary_button.dart';
import 'register_page.dart';
import 'email_login_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFFF4D4D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF050507),
          body: Stack(
            children: [
              Positioned(
                top: -size.height * 0.1,
                right: -size.width * 0.2,
                child: _buildGlow(
                  const Color(0xFFFDE047).withValues(alpha: 0.12),
                  300,
                ),
              ),
              Positioned(
                bottom: -size.height * 0.2,
                left: -size.width * 0.2,
                child: _buildGlow(
                  const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  400,
                ),
              ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, 40, 28, bottomPadding + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 40),

                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.white70],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          "THIẾT BỊ\nCÔNG NGHỆ\nCAO CẤP",
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'GearHub – Hệ sinh thái thiết bị tối thượng cho không gian sáng tạo của bạn.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.4),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 50),

                      SocialLoginButton(
                        label: 'TIẾP TỤC VỚI GOOGLE',
                        iconPath: 'google',
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final deviceId = await DeviceUtils.getDeviceId(
                            getIt<SecureStorageService>(),
                          );
                          if (context.mounted) {
                            context.read<AuthCubit>().loginWithGoogle(
                              deviceId: deviceId,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      SocialLoginButton(
                        label: 'TIẾP TỤC VỚI FACEBOOK',
                        iconPath: 'facebook',
                        onTap: () => HapticFeedback.mediumImpact(),
                      ),
                      const SizedBox(height: 32),

                      _buildDivider(),
                      const SizedBox(height: 32),

                      AuthPrimaryButton(
                        label: 'ĐĂNG NHẬP VỚI EMAIL',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EmailLoginPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),

                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFDE047),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFDE047).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Icon(LucideIcons.zap, color: Color(0xFFFDE047), size: 32),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.05),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'HOẶC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.2),
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.05),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
        },
        behavior: HitTestBehavior.opaque,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, letterSpacing: 0.5),
            children: [
              TextSpan(
                text: "CHƯA CÓ TÀI KHOẢN? ",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const TextSpan(
                text: 'ĐĂNG KÝ NGAY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDE047),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
