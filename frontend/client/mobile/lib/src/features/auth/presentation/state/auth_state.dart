import 'package:equatable/equatable.dart';
import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

///gửi otp register
class AuthRegisterOtpSent extends AuthState {
  final String message;
  final String email;

  const AuthRegisterOtpSent({required this.message, required this.email});

  @override
  List<Object?> get props => [message, email];
}

///gửi otp quên pass
class AuthForgotPasswordOtpSent extends AuthState {
  final String message;
  final String email;

  const AuthForgotPasswordOtpSent({required this.message, required this.email});

  @override
  List<Object?> get props => [message, email];
}

///xác nhận otp quên pass
class AuthForgotPasswordOtpVerified extends AuthState {
  final String email;
  final String otp;

  const AuthForgotPasswordOtpVerified({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

///cập nhật pass thành công
class AuthPasswordResetSuccess extends AuthState {
  final String message;

  const AuthPasswordResetSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

///login thành công
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthProfileUpdateSuccess extends AuthAuthenticated {
  final bool emailChangeOtpSent;
  final String? pendingEmail;

  const AuthProfileUpdateSuccess({
    required super.user,
    required this.emailChangeOtpSent,
    this.pendingEmail,
  });

  @override
  List<Object?> get props => [user, emailChangeOtpSent, pendingEmail];
}

///unauthenticated - 401
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

///error
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
