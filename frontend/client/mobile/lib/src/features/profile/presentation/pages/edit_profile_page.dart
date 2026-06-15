import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';

class EditProfilePage extends StatefulWidget {
  final UserEntity user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  DateTime? _selectedBirthday;
  String? _selectedGender;
  File? _pickedImage;
  bool _emailOtpSheetOpen = false;
  double _scrollOffset = 0.0;

  String? _nameError;
  String? _emailError;
  String? _phoneError;

  static const _genderOptions = <String, String>{
    'MALE': 'Nam',
    'FEMALE': 'Nữ',
    'OTHER': 'Khác',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _selectedBirthday = widget.user.dateOfBirth;
    _selectedGender = widget.user.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      HapticFeedback.mediumImpact();
      setState(() => _pickedImage = File(pickedFile.path));
    } catch (e) {
      _showSnackBar('Lỗi khi chọn ảnh: $e', isError: true);
    }
  }

  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthday ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    HapticFeedback.selectionClick();
    setState(() => _selectedBirthday = picked);
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Vui lòng nhập họ tên đầy đủ' : null;
      _emailError = email.isEmpty
          ? 'Vui lòng nhập email'
          : (!_isValidEmail(email) ? 'Email không hợp lệ' : null);
      _phoneError = (phone.isNotEmpty && !_isValidVietnamesePhone(phone))
          ? 'Số điện thoại không hợp lệ'
          : null;
    });

    if (_nameError != null || _emailError != null || _phoneError != null) {
      HapticFeedback.lightImpact();
      return;
    }

    HapticFeedback.heavyImpact();
    context.read<AuthCubit>().updateProfile(
      email: email != widget.user.email ? email : null,
      fullName: name,
      phone: phone.isNotEmpty ? phone : null,
      dateOfBirth: _selectedBirthday,
      gender: _selectedGender,
      filePath: _pickedImage?.path,
    );
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  bool _isValidVietnamesePhone(String value) {
    return RegExp(r'^(84|0[35789])([0-9]{8})$').hasMatch(value);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _showEmailOtpSheet(String pendingEmail) async {
    if (_emailOtpSheetOpen) return;
    _emailOtpSheetOpen = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _OtpSheetContent(
          pendingEmail: pendingEmail,
          onSnackBar: (msg) => _showSnackBar(msg, isError: true),
        );
      },
    );

    _emailOtpSheetOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state is AuthProfileUpdateSuccess) {
          if (state.emailChangeOtpSent && state.pendingEmail != null) {
            _showSnackBar('Mã OTP đã được gửi tới email mới');
            await _showEmailOtpSheet(state.pendingEmail!);
            return;
          }

          _showSnackBar('Cập nhật hồ sơ thành công');
          final navigator = Navigator.of(context);
          if (mounted && navigator.canPop()) {
            navigator.pop();
          }
          return;
        }

        if (state is AuthAuthenticated && _emailOtpSheetOpen) {
          _emailOtpSheetOpen = false;
          final navigator = Navigator.of(context);
          if (mounted && navigator.canPop()) {
            navigator.pop();
          }
          _showSnackBar('Đổi email thành công');
          if (mounted && navigator.canPop()) {
            navigator.pop();
          }
          return;
        }

        if (state is AuthError) {
          _showSnackBar(state.message, isError: true);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              _ProfileBackdrop(isDark: isDark),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification) {
                        setState(() {
                          _scrollOffset = scrollNotification.metrics.pixels;
                        });
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.top + 60,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(22, 16, 22, 128),
                          sliver: SliverToBoxAdapter(
                            child: _ProfilePanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildAvatarSection(theme, cs, isLoading),
                                  const SizedBox(height: 18),
                                  Text(
                                    _nameController.text.trim().isEmpty
                                        ? 'GearHub User'
                                        : _nameController.text.trim(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.user.role == 'ADMIN'
                                        ? 'Quản trị viên'
                                        : 'Thành viên GearHub',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 34),
                                  _ProfileTextField(
                                    label: 'Họ và tên',
                                    controller: _nameController,
                                    errorText: _nameError,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (_) {
                                      setState(() {});
                                      if (_nameError != null) {
                                        setState(() => _nameError = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  _ProfileTextField(
                                    label: 'Email',
                                    controller: _emailController,
                                    errorText: _emailError,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    trailing:
                                        _emailController.text.trim() ==
                                            widget.user.email
                                        ? const Icon(
                                            Icons.verified_rounded,
                                            color: AppColors.success,
                                            size: 17,
                                          )
                                        : const Icon(
                                            Icons.mark_email_unread_rounded,
                                            color: AppColors.warning,
                                            size: 17,
                                          ),
                                    onChanged: (_) {
                                      setState(() {});
                                      if (_emailError != null) {
                                        setState(() => _emailError = null);
                                      }
                                    },
                                  ),
                                  if (_emailController.text.trim() !=
                                      widget.user.email) ...[
                                    const SizedBox(height: 7),
                                    Text(
                                      'Email mới sẽ cần xác minh bằng OTP sau khi lưu.',
                                      style: TextStyle(
                                        color: AppColors.warning.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  _ProfileTextField(
                                    label: 'Số điện thoại',
                                    controller: _phoneController,
                                    errorText: _phoneError,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    onChanged: (_) {
                                      if (_phoneError != null) {
                                        setState(() => _phoneError = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 28),
                                  Text(
                                    'Ngày sinh',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _BirthdayPickerRow(
                                    birthday: _selectedBirthday,
                                    onTap: _selectBirthday,
                                  ),
                                  const SizedBox(height: 28),
                                  Text(
                                    'Giới tính',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _GenderSelector(
                                    value: _selectedGender,
                                    options: _genderOptions,
                                    onChanged: (value) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedGender = value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              GlassmorphicHeader(
                scrollOffset: _scrollOffset,
                title: 'Cập nhật hồ sơ',
                isTransparentAtTop: true,
                centerTitle: true,
                onBack: () => Navigator.pop(context),
              ),
              _buildFloatingBottomBar(theme, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ThemeData theme, ColorScheme cs, bool isLoading) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 108,
            height: 108,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipOval(
              child: _pickedImage != null
                  ? Image.file(_pickedImage!, fit: BoxFit.cover)
                  : (widget.user.avatarUrl?.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: widget.user.avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: cs.primary,
                                strokeWidth: 1.5,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildInitialAvatar(cs),
                          )
                        : _buildInitialAvatar(cs)),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: GestureDetector(
              onTap: isLoading ? null : _pickImage,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(LucideIcons.link, color: cs.onPrimary, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        widget.user.fullName?.isNotEmpty == true
            ? widget.user.fullName![0].toUpperCase()
            : 'G',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: cs.primary,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildFloatingBottomBar(ThemeData theme, ColorScheme cs) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              22,
              16,
              22,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.78),
              border: Border(
                top: BorderSide(color: cs.outlineVariant, width: 0.6),
              ),
            ),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: isLoading ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      disabledBackgroundColor: cs.primary.withValues(
                        alpha: 0.3,
                      ),
                      disabledForegroundColor: cs.onPrimary.withValues(
                        alpha: 0.5,
                      ),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Text('Lưu thay đổi'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBackdrop extends StatelessWidget {
  final bool isDark;

  const _ProfileBackdrop({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF07070A), Color(0xFF101014)]
                : const [Color(0xFFFFFFFF), Color(0xFFF8F9FC)],
          ),
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  final Widget child;

  const _ProfilePanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.trailing,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      cursorColor: cs.primary,
      onChanged: onChanged,
      style: TextStyle(
        color: cs.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        errorText: errorText,
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: trailing,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.ctaSub, width: 1.0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.ctaSub.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.only(top: 18, bottom: 8),
      ),
    );
  }
}

class _BirthdayPickerRow extends StatelessWidget {
  final DateTime? birthday;
  final VoidCallback onTap;

  const _BirthdayPickerRow({required this.birthday, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final day = birthday == null ? '--' : DateFormat('dd').format(birthday!);
    final month = birthday == null
        ? 'Chọn tháng'
        : _vietnameseMonths[birthday!.month - 1];
    final year = birthday == null
        ? '----'
        : DateFormat('yyyy').format(birthday!);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: _DatePart(value: day, isPlaceholder: birthday == null),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _DatePart(value: month, isPlaceholder: birthday == null),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DatePart(value: year, isPlaceholder: birthday == null),
          ),
        ],
      ),
    );
  }
}

const _vietnameseMonths = [
  'Tháng 1',
  'Tháng 2',
  'Tháng 3',
  'Tháng 4',
  'Tháng 5',
  'Tháng 6',
  'Tháng 7',
  'Tháng 8',
  'Tháng 9',
  'Tháng 10',
  'Tháng 11',
  'Tháng 12',
];

class _DatePart extends StatelessWidget {
  final String value;
  final bool isPlaceholder;

  const _DatePart({required this.value, this.isPlaceholder = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.ctaSub.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaceholder ? AppColors.ctaSub : cs.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const _GenderSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = options.entries.toList();
    final selectedIndex = entries.indexWhere((e) => e.key == value);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth - 10;
          final itemWidth = totalWidth / entries.length;

          return Padding(
            padding: const EdgeInsets.all(5),
            child: Stack(
              children: [
                //sliding thumb
                if (selectedIndex != -1)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    left: selectedIndex * itemWidth,
                    width: itemWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                //items
                Row(
                  children: entries.map((entry) {
                    final selected = entry.key == value;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(entry.key),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: selected ? cs.onPrimary : AppColors.ctaSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                            child: Text(entry.value),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OtpSheetContent extends StatefulWidget {
  final String pendingEmail;
  final Function(String) onSnackBar;

  const _OtpSheetContent({
    required this.pendingEmail,
    required this.onSnackBar,
  });

  @override
  State<_OtpSheetContent> createState() => _OtpSheetContentState();
}

class _OtpSheetContentState extends State<_OtpSheetContent> {
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.mail,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xác minh email mới',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.pendingEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _OtpField(controller: _otpController, enabled: !isLoading),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            final otp = _otpController.text.trim();
                            if (otp.length != 6) {
                              widget.onSnackBar('Vui lòng nhập đủ 6 số OTP');
                              return;
                            }
                            context.read<AuthCubit>().verifyEmailChange(
                              otp: otp,
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Text(
                            'Xác nhận email',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _OtpField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: 6,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
        color: cs.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 10,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '000000',
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.35),
          letterSpacing: 10,
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.ctaSub.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.ctaSub.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
      ),
    );
  }
}
