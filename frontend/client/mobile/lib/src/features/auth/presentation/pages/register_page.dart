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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mật khẩu không khớp'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Vui lòng đồng ý với các điều khoản và điều kiện',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final deviceId = await DeviceUtils.getDeviceId(
      getIt<SecureStorageService>(),
    );

    if (!mounted) return;

    // bloc logic
    context.read<AuthCubit>().requestRegister(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      deviceId: deviceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterOtpSent) {
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
                  otpPurpose: OtpPurpose.register,
                ),
              ),
            ),
          );
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
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
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 32),
                            const Text(
                              'TẠO TÀI KHOẢN\nMỚI',
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
                              'Tham gia GearHub để trải nghiệm hệ sinh thái thiết bị cao cấp nhất.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.5),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AuthTextField(
                                    label: 'HỌ TÊN',
                                    controller: _fullNameController,
                                    prefixIcon: LucideIcons.user,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Trống'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AuthTextField(
                                    label: 'SĐT',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: LucideIcons.phone,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Trống'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AuthTextField(
                              label: 'ĐỊA CHỈ EMAIL',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: LucideIcons.mail,
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Email không hợp lệ'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AuthTextField(
                              label: 'MẬT KHẨU',
                              controller: _passwordController,
                              isPassword: true,
                              prefixIcon: LucideIcons.lock,
                              validator: (v) => (v != null && v.length < 6)
                                  ? 'Tối thiểu 6 ký tự'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AuthTextField(
                              label: 'XÁC NHẬN MẬT KHẨU',
                              controller: _confirmPasswordController,
                              isPassword: true,
                              prefixIcon: LucideIcons.shieldCheck,
                              validator: (v) => v != _passwordController.text
                                  ? 'Không khớp'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _agreeTerms = !_agreeTerms);
                              },
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _agreeTerms
                                          ? const Color(0xFFFDE047)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _agreeTerms
                                            ? const Color(0xFFFDE047)
                                            : Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _agreeTerms
                                        ? const Icon(
                                            LucideIcons.check,
                                            size: 14,
                                            color: Colors.black,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        children: const [
                                          TextSpan(text: 'Tôi đồng ý với '),
                                          TextSpan(
                                            text: 'Điều khoản & Chính sách',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                      letterSpacing: 0.5,
                                    ),
                                    children: [
                                      TextSpan(text: 'ĐÃ CÓ TÀI KHOẢN? '),
                                      TextSpan(
                                        text: 'ĐĂNG NHẬP',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFFDE047),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: EdgeInsets.fromLTRB(28, 20, 28, bottomPadding + 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF07070A),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return AuthPrimaryButton(
                        label: 'BẮT ĐẦU NGAY',
                        isLoading: state is AuthLoading,
                        onTap: _handleRegister,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
