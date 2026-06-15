import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';

class ProfileUpdateResult {
  final UserEntity user;
  final bool emailChangeOtpSent;
  final String? pendingEmail;

  const ProfileUpdateResult({
    required this.user,
    required this.emailChangeOtpSent,
    this.pendingEmail,
  });
}
