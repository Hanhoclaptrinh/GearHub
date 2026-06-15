import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/src/features/preferences/data/models/shopping_preferences_model.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.fullName,
    super.avatarUrl,
    super.phone,
    super.address,
    super.dateOfBirth,
    super.gender,
    super.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final dateOfBirthValue = json['dateOfBirth'] ?? profile?['dateOfBirth'];

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'USER',
      fullName: (json['fullName'] ?? profile?['fullName']) as String?,
      avatarUrl: (json['avatarUrl'] ?? profile?['avatarUrl']) as String?,
      phone: (json['phone'] ?? profile?['phone']) as String?,
      address: (json['address'] ?? profile?['address']) as String?,
      dateOfBirth: dateOfBirthValue is String
          ? DateTime.tryParse(dateOfBirthValue)?.toLocal()
          : null,
      gender: (json['gender'] ?? profile?['gender']) as String?,
      preferences: ShoppingPreferencesModel.fromJson(
        (json['preferences'] ?? profile?['preferences']) as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'role': role,
    'fullName': fullName,
    'avatarUrl': avatarUrl,
    'phone': phone,
    'address': address,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'gender': gender,
    'preferences': ShoppingPreferencesModel.fromEntity(preferences).toJson(),
  };
}
