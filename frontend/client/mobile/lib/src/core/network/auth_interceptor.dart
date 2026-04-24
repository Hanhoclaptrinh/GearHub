import 'package:dio/dio.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService storageService;
  final Dio dio;

  AuthInterceptor({required this.storageService, required this.dio});

  // kiem tra truoc khi request gui len server
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // cac API khong can token
    final noAuthPaths = [
      '/auth/login',
      '/auth/register/request',
      '/auth/register/verify',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/auth/refresh',
    ];

    // kiem tra xem req hien tai can token khong
    final needsAuth = !noAuthPaths.any((p) => options.path.contains(p));

    if (needsAuth) {
      // lay token tu storage
      final token = await storageService.accessToken;

      // them vao header
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // cho req tiep tuc di den server
    handler.next(options);
  }

  // xu ly refresh token khi token het han
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // loi phai la het han hoac sai token moi duoc refresh
    // req bi loi khong duoc phep cap refresh (tranh loop)
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      try {
        // lay rt, user id, device id tu storage
        final rt = await storageService.refreshToken;
        final uid = await storageService.userId;
        final did = await storageService.deviceId;

        if (rt != null && uid != null) {
          // xin cap token moi
          final response = await dio.post(
            '/auth/refresh',
            data: {
              'refreshToken': rt,
              'userId': uid,
              'deviceId': did ?? 'mobile',
            },
          );

          final newAt = response.data['accessToken'] as String;
          final newRt = response.data['refreshToken'] as String;

          // luu token moi
          await storageService.saveTokens(
            accessToken: newAt,
            refreshToken: newRt,
          );

          // sua lai header cua req bi loi ban new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAt';
          // retry req
          final retryResponse = await dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        await storageService.clearAll();
      }
    }

    handler.next(err);
  }
}
