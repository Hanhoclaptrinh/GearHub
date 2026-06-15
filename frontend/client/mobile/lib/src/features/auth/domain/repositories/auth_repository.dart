import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/src/features/auth/domain/entities/auth_tokens.dart';
import 'package:mobile/src/features/auth/domain/entities/profile_update_result.dart';

abstract class AuthRepository {
  Future<String> requestRegister({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String deviceId,
  });

  Future<({UserEntity user, AuthTokens tokens})> verifyRegister({
    required String email,
    required String otp,
    required String deviceId,
  });

  Future<({UserEntity user, AuthTokens tokens})> login({
    required String identifier,
    required String password,
    required String deviceId,
  });

  Future<({UserEntity user, AuthTokens tokens})> loginWithGoogle({
    required String idToken,
    required String deviceId,
  });

  Future<String> forgotPassword({required String email});

  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  });

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<({UserEntity user, AuthTokens tokens})> changePassword({
    required String oldPassword,
    required String newPassword,
    required String deviceId,
  });

  Future<UserEntity> getMe();

  Future<ProfileUpdateResult> updateProfile({
    String? email,
    String? fullName,
    String? phone,
    String? address,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? filePath,
  });

  Future<UserEntity> verifyEmailChange({required String otp});

  Future<void> logout();

  Future<bool> isLoggedIn();
}
