import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/social_login_button.dart';
import '../widgets/auth_primary_button.dart';
import 'register_page.dart';
import 'email_login_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 28, bottomPadding + 24),
              child: Column(
                children: [
                  // illustration
                  SvgPicture.asset(
                    'assets/images/login-illustration.svg',
                    height: 240,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32),

                  // heading
                  const Text(
                    "Đăng Nhập",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A0A0F),
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Khám phá các sản phẩm công nghệ hàng đầu\n được tuyển chọn ở GearHub.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // social buttons
                  SocialLoginButton(
                    label: 'Đăng nhập với Google',
                    iconPath: 'google',
                    onTap: () {
                      print('Login with Google');
                    },
                  ),
                  const SizedBox(height: 12),
                  SocialLoginButton(
                    label: 'Đăng nhập với Facebook',
                    iconPath: 'facebook',
                    onTap: () {
                      print('Login with Facebook');
                    },
                  ),
                  const SizedBox(height: 24),

                  // divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Hoặc',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // login with email
                  AuthPrimaryButton(
                    label: 'Đăng nhập với Email',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EmailLoginPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // create account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Chưa có tài khoản? ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A0A0F),
                            decoration: TextDecoration.underline,
                            decorationThickness: 1.5,
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
      ),
    );
  }
}
