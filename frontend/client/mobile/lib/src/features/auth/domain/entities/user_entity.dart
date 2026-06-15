import 'package:mobile/src/features/preferences/domain/entities/shopping_preferences.dart';

class UserEntity {
  final String id;
  final String email;
  final String role;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? gender;
  final ShoppingPreferences preferences;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.gender,
    this.preferences = const ShoppingPreferences(),
  });

  bool get shouldAskPreferenceOnboarding => preferences.shouldAskOnboarding;
}
