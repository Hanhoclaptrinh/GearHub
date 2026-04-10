import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? avatar;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.avatar,
  });

  @override
  List<Object?> get props => [id, email, fullName, avatar];
}
