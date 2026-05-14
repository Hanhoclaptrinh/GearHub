import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/core/utils/device_utils.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import '../widgets/auth_primary_button.dart';
import 'reset_password_page.dart';

enum OtpPurpose { register, resetPassword }

class OtpPage extends StatefulWidget {
  final String email;
  final OtpPurpose otpPurpose;

  const OtpPage({super.key, required this.email, required this.otpPurpose});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const _otpLength = 6;
  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  Timer? _resendTimer;
  int _resendCountdown = 60; // bo dem nguoc thoi gian gui lai otp
  bool _canResend = false;

  Timer? _expiryTimer; // bo dem nguoc thoi gian otp con han dung
  int _expiryCountdown = 300; // 5 phut

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _expiryTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startTimers() {
    _startResendTimer();
    _startExpiryTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 0) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  void _startExpiryTimer() {
    _expiryCountdown = 300;
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expiryCountdown <= 0) {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Mã OTP đã hết hạn. Vui lòng gửi lại.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) setState(() => _expiryCountdown--);
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is AuthForgotPasswordOtpVerified) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AuthCubit>(),
                child: ResetPasswordPage(email: state.email, otp: state.otp),
              ),
            ),
          );
        } else if (state is AuthError) {
          _showError(state.message);
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildBackButton(),
                          const SizedBox(height: 48),

                          const Text(
                            'XÁC THỰC\nMÃ OTP',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.5),
                                height: 1.6,
                                letterSpacing: 0.1,
                                fontFamily: 'Inter',
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'Vui lòng nhập mã 6 số đã được gửi tới ',
                                ),
                                TextSpan(
                                  text: widget.email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFDE047),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          // OTP input group
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              _otpLength,
                              (index) => _buildOtpBox(index),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // countdown & resend
                          Center(
                            child: Column(
                              children: [
                                _buildExpiryTimer(),
                                const SizedBox(height: 40),
                                _buildResendSection(),
                              ],
                            ),
                          ),
                        ],
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
                        label: 'XÁC NHẬN',
                        isLoading: state is AuthLoading,
                        onTap: _handleVerify,
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

  void _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập mã OTP gồm 6 chữ số'),
          backgroundColor: const Color(0xFFFF4D4D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    if (widget.otpPurpose == OtpPurpose.register) {
      final deviceId = await DeviceUtils.getDeviceId(
        getIt<SecureStorageService>(),
      );
      if (!mounted) return;

      context.read<AuthCubit>().verifyRegister(
        email: widget.email,
        otp: otp,
        deviceId: deviceId,
      );
    } else {
      context.read<AuthCubit>().verifyForgotPasswordOtp(
        email: widget.email,
        otp: otp,
      );
    }
  }

  void _handleResend() {
    if (!_canResend) return;
    HapticFeedback.lightImpact();

    if (widget.otpPurpose == OtpPurpose.register) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng quay lại và gửi lại form đăng ký'),
          backgroundColor: const Color(0xFFFF4D4D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } else {
      context.read<AuthCubit>().forgotPassword(email: widget.email);
      setState(() {
        _resendCountdown = 60;
        _canResend = false;
        _expiryCountdown = 300;
      });
      _startTimers();
    }
  }

  Widget _buildOtpBox(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? const Color(0xFFFDE047)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: _focusNodes[index].hasFocus
            ? [
                BoxShadow(
                  color: const Color(0xFFFDE047).withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Center(
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                _controllers[index].text.isEmpty &&
                index > 0) {
              _focusNodes[index - 1].requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < _otpLength - 1) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                  _handleVerify();
                }
              }
            },
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryTimer() {
    bool isUrgent = _expiryCountdown < 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFFF4D4D).withValues(alpha: 0.1)
            : const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFFF4D4D).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clock,
            size: 14,
            color: isUrgent ? const Color(0xFFFF4D4D) : Colors.white54,
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(_expiryCountdown),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isUrgent ? const Color(0xFFFF4D4D) : Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          "KHÔNG NHẬN ĐƯỢC MÃ?",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _canResend ? _handleResend : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _canResend ? 1.0 : 0.5,
            child: Text(
              _canResend
                  ? 'GỬI LẠI MÃ NGAY'
                  : 'GỬI LẠI SAU ${_resendCountdown}S',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _canResend ? const Color(0xFFFDE047) : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF4D4D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
