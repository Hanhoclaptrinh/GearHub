import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/src/features/auth/data/models/auth_tokens_model.dart';
import 'package:mobile/src/features/auth/data/models/user_model.dart';
import 'package:mobile/src/features/auth/domain/entities/auth_tokens.dart';
import 'package:mobile/src/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final SecureStorageService _storageService;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required SecureStorageService storageService,
  })  : _remoteDatasource = remoteDatasource,
        _storageService = storageService;

  @override
  Future<String> requestRegister({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String deviceId,
  }) async {
    final response = await _remoteDatasource.requestRegister(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      deviceId: deviceId,
    );
    return response['message'] as String;
  }

  @override
  Future<({UserEntity user, AuthTokens tokens})> verifyRegister({
    required String email,
    required String otp,
    required String deviceId,
  }) async {
    final response = await _remoteDatasource.verifyRegister(
      email: email,
      otp: otp,
      deviceId: deviceId,
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokensModel.fromRegisterJson(
      data['tokens'] as Map<String, dynamic>,
    );

    await _persistAuthData(user, tokens);

    return (user: user as UserEntity, tokens: tokens as AuthTokens);
  }

  @override
  Future<({UserEntity user, AuthTokens tokens})> login({
    required String identifier,
    required String password,
    required String deviceId,
  }) async {
    final response = await _remoteDatasource.login(
      identifier: identifier,
      password: password,
      deviceId: deviceId,
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokensModel.fromLoginJson(
      data['tokens'] as Map<String, dynamic>,
    );

    await _persistAuthData(user, tokens);

    return (user: user as UserEntity, tokens: tokens as AuthTokens);
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    final response = await _remoteDatasource.forgotPassword(email: email);
    return response['message'] as String;
  }

  @override
  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _remoteDatasource.verifyForgotPasswordOtp(
      email: email,
      otp: otp,
    );
    return response['message'] as String;
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _remoteDatasource.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
    return response['message'] as String;
  }

  @override
  Future<({UserEntity user, AuthTokens tokens})> changePassword({
    required String oldPassword,
    required String newPassword,
    required String deviceId,
  }) async {
    final response = await _remoteDatasource.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      deviceId: deviceId,
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokensModel.fromChangePasswordJson(
      data['tokens'] as Map<String, dynamic>,
    );

    await _persistAuthData(user, tokens);

    return (user: user as UserEntity, tokens: tokens as AuthTokens);
  }

  @override
  Future<UserEntity> getMe() async {
    final response = await _remoteDatasource.getMe();
    return UserModel.fromJson(response);
  }

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? avatarUrl,
    String? filePath,
  }) async {
    final response = await _remoteDatasource.updateProfile(
      fullName: fullName,
      phone: phone,
      address: address,
      avatarUrl: avatarUrl,
      filePath: filePath,
    );

    if (response.containsKey('data')) {
      final data = response['data'];
      if (data is Map<String, dynamic> && data.containsKey('user')) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      return UserModel.fromJson(response);
    }
      return UserModel.fromJson(response);
    
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDatasource.logout();
    } finally {
      await _storageService.clearAll();
    }
  }

  @override
  Future<bool> isLoggedIn() => _storageService.hasTokens;

  Future<void> _persistAuthData(UserModel user, AuthTokens tokens) async {
    await Future.wait([
      _storageService.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      ),
      _storageService.saveUserId(user.id),
    ]);
  }
}
