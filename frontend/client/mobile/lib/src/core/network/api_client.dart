import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/src/core/constants/api_constant.dart';
import 'package:mobile/src/core/network/auth_interceptor.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';

class ApiClient {
  late final Dio dio;

  ApiClient({required SecureStorageService storageService}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstant.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(storageService: storageService, dio: dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
    ]);
  }
}
