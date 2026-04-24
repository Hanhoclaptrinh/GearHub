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

// gui otp dang ky tai khoan
class AuthRegisterOtpSent extends AuthState {
  final String message;
  final String email;

  const AuthRegisterOtpSent({required this.message, required this.email});

  @override
  List<Object?> get props => [message, email];
}

// gui otp quen pass
class AuthForgotPasswordOtpSent extends AuthState {
  final String message;
  final String email;

  const AuthForgotPasswordOtpSent({required this.message, required this.email});

  @override
  List<Object?> get props => [message, email];
}

// xac nhan otp quen pass
class AuthForgotPasswordOtpVerified extends AuthState {
  final String email;
  final String otp;

  const AuthForgotPasswordOtpVerified({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

// cap nhat pass thanh cong
class AuthPasswordResetSuccess extends AuthState {
  final String message;

  const AuthPasswordResetSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

// login thanh cong
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

// unauthenticated - 401
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// error
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
