import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      initialValue: widget.controller.text,
      builder: (state) {
        final hasError = state.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Focus(
              onFocusChange: (focused) {
                setState(() => _isFocused = focused);
                if (!focused) {
                  state.validate();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasError
                        ? const Color(0xFFFF4D4D)
                        : _isFocused
                            ? const Color(0xFF0A0A0F)
                            : const Color(0xFFE5E7EB),
                    width: (_isFocused || hasError) ? 1.5 : 1,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: hasError
                                ? const Color(0xFFFF4D4D).withValues(alpha: 0.06)
                                : const Color(0xFF0A0A0F).withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: widget.controller,
                  obscureText: widget.isPassword && _obscureText,
                  keyboardType: widget.keyboardType,
                  onChanged: (value) {
                    state.didChange(value);
                  },
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0A0A0F),
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.label,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasError
                          ? const Color(0xFFFF4D4D)
                          : _isFocused
                              ? const Color(0xFF0A0A0F)
                              : const Color(0xFF9CA3AF),
                      letterSpacing: -0.1,
                    ),
                    floatingLabelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasError
                          ? const Color(0xFFFF4D4D)
                          : const Color(0xFF0A0A0F),
                    ),
                    prefixIcon: widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            size: 20,
                            color: hasError
                                ? const Color(0xFFFF4D4D)
                                : _isFocused
                                    ? const Color(0xFF0A0A0F)
                                    : const Color(0xFFB0B0B0),
                          )
                        : null,
                    suffixIcon: widget.isPassword
                        ? GestureDetector(
                            onTap: () =>
                                setState(() => _obscureText = !_obscureText),
                            child: Icon(
                              _obscureText
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              size: 20,
                              color: hasError
                                  ? const Color(0xFFFF4D4D)
                                  : const Color(0xFF9CA3AF),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFFF4D4D),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
