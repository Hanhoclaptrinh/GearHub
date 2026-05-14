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
                  color: const Color(0xFF14141E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasError
                        ? const Color(0xFFFF4D4D)
                        : _isFocused
                            ? const Color(0xFFFDE047)
                            : Colors.white.withValues(alpha: 0.08),
                    width: (_isFocused || hasError) ? 1.5 : 1,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: hasError
                                ? const Color(0xFFFF4D4D).withValues(alpha: 0.1)
                                : const Color(0xFFFDE047).withValues(alpha: 0.1),
                            blurRadius: 20,
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
                  cursorColor: const Color(0xFFFDE047),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.label,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasError
                          ? const Color(0xFFFF4D4D)
                          : _isFocused
                              ? const Color(0xFFFDE047)
                              : Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0.1,
                    ),
                    floatingLabelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasError
                          ? const Color(0xFFFF4D4D)
                          : const Color(0xFFFDE047),
                      letterSpacing: 0.5,
                    ),
                    prefixIcon: widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            size: 18,
                            color: hasError
                                ? const Color(0xFFFF4D4D)
                                : _isFocused
                                    ? const Color(0xFFFDE047)
                                    : Colors.white.withValues(alpha: 0.3),
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
                              size: 18,
                              color: hasError
                                  ? const Color(0xFFFF4D4D)
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF4D4D),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

