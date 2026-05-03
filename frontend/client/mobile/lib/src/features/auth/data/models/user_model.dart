import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.fullName,
    super.avatarUrl,
    super.phone,
    super.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'USER',
      fullName: (json['fullName'] ?? profile?['fullName']) as String?,
      avatarUrl: (json['avatarUrl'] ?? profile?['avatarUrl']) as String?,
      phone: (json['phone'] ?? profile?['phone']) as String?,
      address: (json['address'] ?? profile?['address']) as String?,
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
      };
}
