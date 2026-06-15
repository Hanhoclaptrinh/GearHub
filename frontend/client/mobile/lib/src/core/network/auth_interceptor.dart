import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';

class AuthInterceptor extends Interceptor {
  static const _retryKey = 'auth_retry';
  static const _refreshBuffer = Duration(minutes: 5);

  final SecureStorageService storageService;
  final Dio dio;
  Future<String>? _refreshFuture;

  AuthInterceptor({required this.storageService, required this.dio});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicPath(options.path)) {
      handler.next(options);
      return;
    }

    try {
      var token = await storageService.accessToken;

      if (token != null && token.isNotEmpty && _isExpiringSoon(token)) {
        token = await _refreshAccessToken();
      }

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (error) {
      await _logout();
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final canRefresh =
        err.response?.statusCode == 401 &&
        !_isPublicPath(request.path) &&
        request.extra[_retryKey] != true;

    if (canRefresh) {
      try {
        final newAccessToken = await _refreshAccessToken();

        request.extra[_retryKey] = true;
        request.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await dio.fetch(request);
        return handler.resolve(retryResponse);
      } catch (_) {
        await _logout();
      }
    }

    handler.next(err);
  }

  bool _isPublicPath(String path) {
    const publicPaths = [
      '/auth/login',
      '/auth/google',
      '/auth/register/request',
      '/auth/register/verify',
      '/auth/forgot-password',
      '/auth/verify-forgot-password',
      '/auth/reset-password',
      '/auth/refresh',
    ];

    return publicPaths.any((publicPath) => path.contains(publicPath));
  }

  bool _isExpiringSoon(String token) {
    final expiresAt = _readJwtExpiresAt(token);
    if (expiresAt == null) return false;

    return DateTime.now().add(_refreshBuffer).isAfter(expiresAt);
  }

  DateTime? _readJwtExpiresAt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);
      final exp = data is Map<String, dynamic> ? data['exp'] : null;

      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _refreshAccessToken() {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _doRefreshAccessToken();
    _refreshFuture = refresh;

    return refresh.whenComplete(() {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    });
  }

  Future<String> _doRefreshAccessToken() async {
    final refreshToken = await storageService.refreshToken;
    final userId = await storageService.userId;
    final deviceId = await storageService.deviceId;

    if (refreshToken == null || refreshToken.isEmpty || userId == null) {
      throw StateError('Missing refresh token or user id');
    }

    final response = await dio.post(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
        'userId': userId,
        'deviceId': deviceId ?? 'mobile',
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('Invalid refresh response');
    }

    final newAccessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];

    if (newAccessToken is! String ||
        newAccessToken.isEmpty ||
        newRefreshToken is! String ||
        newRefreshToken.isEmpty) {
      throw StateError('Invalid refresh tokens');
    }

    await storageService.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );

    return newAccessToken;
  }

  Future<void> _logout() async {
    await storageService.clearAll();
    getIt<AuthCubit>().forceLogout();
  }
}
