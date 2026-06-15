import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/core/utils/device_utils.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
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
  int _resendCountdown = 60;
  bool _canResend = false;

  Timer? _expiryTimer;
  int _expiryCountdown = 300;

  bool _isSuccess = false;
  bool _isError = false;
  String? _errorMessage;

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
          setState(() {
            _isError = true;
            _errorMessage = 'Mã OTP đã hết hạn. Vui lòng gửi lại.';
          });
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
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        if (state is AuthAuthenticated) {
          setState(() {
            _isSuccess = true;
            _isError = false;
            _errorMessage = null;
          });
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is AuthForgotPasswordOtpVerified) {
          setState(() {
            _isSuccess = true;
            _isError = false;
            _errorMessage = null;
          });
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AuthCubit>(),
                child: ResetPasswordPage(email: state.email, otp: state.otp),
              ),
            ),
          );
        } else if (state is AuthError) {
          setState(() {
            _isError = true;
            _isSuccess = false;
            _errorMessage = state.message;
          });
          //clear all
          for (var c in _controllers) {
            c.clear();
          }
          //focus first
          _focusNodes[0].requestFocus();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned(
                top: size.height * 0.4,
                left: -size.width * 0.45,
                child: SvgPicture.asset(
                  'assets/logo/union-login.svg',
                  width: size.width * 1.4,
                  fit: BoxFit.contain,
                ),
              ),
              SafeArea(
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

                              Text(
                                'Xác thực mã OTP',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  letterSpacing: -1.5,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 48),

                              //OTP input group
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  _otpLength,
                                  (index) => _buildOtpBox(index),
                                ),
                              ),

                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 48),

                              //countdown & resend
                              Center(
                                child: Column(
                                  children: [
                                    _buildExpiryTimer(),
                                    const SizedBox(height: 40),
                                    _buildResendSection(),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 48),

                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  final theme = Theme.of(context);
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              _handleVerify();
                                            },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            theme.colorScheme.primary,
                                        side: BorderSide(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.4),
                                          width: 1.2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            32,
                                          ),
                                        ),
                                      ),
                                      child: isLoading
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      theme.colorScheme.primary,
                                                    ),
                                              ),
                                            )
                                          : const Text(
                                              "XÁC NHẬN",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _otpLength) {
      setState(() {
        _isError = true;
        _isSuccess = false;
        _errorMessage = 'Vui lòng nhập mã OTP gồm 6 chữ số';
      });
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
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
      setState(() {
        _isError = true;
        _isSuccess = false;
        _errorMessage = 'Vui lòng quay lại và gửi lại form đăng ký';
      });
    } else {
      context.read<AuthCubit>().forgotPassword(email: widget.email);
      setState(() {
        _resendCountdown = 60;
        _canResend = false;
        _expiryCountdown = 300;
        _isError = false;
        _errorMessage = null;
      });
      _startTimers();
    }
  }

  Widget _buildOtpBox(int index) {
    Color borderColor = Theme.of(context).colorScheme.outlineVariant;
    if (_isSuccess) {
      borderColor = Colors.green;
    } else if (_isError) {
      borderColor = Colors.redAccent;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 46,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace) {
              if (_isError) {
                setState(() {
                  _isError = false;
                  _errorMessage = null;
                });
              }
              if (_controllers[index].text.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            onChanged: (value) {
              if (_isError) {
                setState(() {
                  _isError = false;
                  _errorMessage = null;
                });
              }
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'Inter',
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              fillColor: Colors.transparent,
              counterText: '',
              contentPadding: EdgeInsets.zero,
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
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFFF4D4D).withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clock,
            size: 14,
            color: isUrgent
                ? const Color(0xFFFF4D4D)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(_expiryCountdown),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isUrgent
                  ? const Color(0xFFFF4D4D)
                  : Theme.of(context).colorScheme.onSurface,
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
          'KHÔNG NHẬN ĐƯỢC MÃ?',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
                color: _canResend
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
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
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Theme.of(context).colorScheme.onSurface,
          size: 22,
        ),
      ),
    );
  }
}
