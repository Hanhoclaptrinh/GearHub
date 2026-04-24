class UserEntity {
  final String id;
  final String email;
  final String role;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.phone,
  });
}
