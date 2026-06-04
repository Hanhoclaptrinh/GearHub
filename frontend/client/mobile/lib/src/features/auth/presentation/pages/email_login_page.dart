import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/core/utils/device_utils.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_primary_button.dart';
import 'otp_page.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // lay device id tu secure storage thong qua DI
    final deviceId = await DeviceUtils.getDeviceId(
      getIt<SecureStorageService>(),
    );

    if (!mounted) return;

    // xu ly logic login thong qua cubit
    context.read<AuthCubit>().login(
      identifier: _emailController.text.trim(),
      password: _passwordController.text,
      deviceId: deviceId,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: const Color(0xFF07070A),
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14141E),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // header
                          const Text(
                            'CHÀO MỪNG\nTRỞ LẠI!',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Vui lòng đăng nhập để tiếp tục trải nghiệm không gian công nghệ đỉnh cao.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.5),
                              height: 1.6,
                              letterSpacing: 0.1,
                            ),
                          ),

                          const SizedBox(height: 48),

                          AuthTextField(
                            label: 'EMAIL HOẶC SỐ ĐIỆN THOẠI',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: LucideIcons.mail,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Vui lòng nhập thông tin';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          AuthTextField(
                            label: 'MẬT KHẨU',
                            controller: _passwordController,
                            isPassword: true,
                            prefixIcon: LucideIcons.lock,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Vui lòng nhập mật khẩu';
                              }
                              if (v.length < 6) {
                                return 'Mật khẩu quá ngắn';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showForgotPasswordSheet(context);
                              },
                              child: const Text(
                                'QUÊN MẬT KHẨU?',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFDE047),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              return AuthPrimaryButton(
                                label: 'ĐĂNG NHẬP',
                                isLoading: state is AuthLoading,
                                onTap: _handleLogin,
                              );
                            },
                          ),

                          const Spacer(),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14141E),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.shieldCheck,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'BẢO MẬT MÃ HÓA TOÀN DIỆN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: bottomPadding + 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // hien thi bottom sheet forgot password
  void _showForgotPasswordSheet(BuildContext context) {
    final resetEmailController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocListener<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state is AuthForgotPasswordOtpSent) {
              Navigator.of(ctx).pop(); // close bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mã OTP đã được gửi về email ${state.email}'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AuthCubit>(),
                    child: OtpPage(
                      email: state.email,
                      otpPurpose: OtpPurpose.resetPassword,
                    ),
                  ),
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
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
          child: Container(
            padding: EdgeInsets.fromLTRB(
              28,
              8,
              28,
              MediaQuery.of(sheetContext).viewInsets.bottom + 32,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF14141E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Form(
              key: resetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const Text(
                    'ĐẶT LẠI MẬT KHẨU',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nhập email đã đăng ký để nhận mã khôi phục tài khoản GearHub của bạn.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  AuthTextField(
                    label: 'EMAIL',
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: LucideIcons.mail,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(v)) {
                        return 'Vui lòng nhập email hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (ctx, state) {
                      return AuthPrimaryButton(
                        label: 'GỬI MÃ KHÔI PHỤC',
                        isLoading: state is AuthLoading,
                        onTap: () {
                          if (resetFormKey.currentState!.validate()) {
                            ctx.read<AuthCubit>().forgotPassword(
                              email: resetEmailController.text.trim(),
                            );
                          }
                        },
                      );
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
}
