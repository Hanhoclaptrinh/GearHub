import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _deviceIdKey = 'device_id';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  ///lưu at, rt vào local storage
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  ///lấy at
  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);

  ///lấy rt
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  ///lưu user id
  Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  ///lấy user id
  Future<String?> get userId => _storage.read(key: _userIdKey);

  ///lưu device id
  Future<void> saveDeviceId(String deviceId) =>
      _storage.write(key: _deviceIdKey, value: deviceId);

  ///lấy device id
  Future<String?> get deviceId => _storage.read(key: _deviceIdKey);

  ///xóa tất cả storage
  Future<void> clearAll() => _storage.deleteAll();

  ///kiểm tra at trong stg
  Future<bool> get hasTokens async {
    final at = await accessToken;
    return at != null && at.isNotEmpty;
  }
}
