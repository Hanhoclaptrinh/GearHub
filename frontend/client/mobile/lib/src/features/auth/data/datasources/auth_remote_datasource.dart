import 'package:dio/dio.dart';

// bridge api va app
class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource({required Dio dio}) : _dio = dio;

  Future<Map<String, dynamic>> requestRegister({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String deviceId,
  }) async {
    final response = await _dio.post(
      '/auth/register/request',
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'deviceId': deviceId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyRegister({
    required String email,
    required String otp,
    required String deviceId,
  }) async {
    final response = await _dio.post(
      '/auth/register/verify',
      data: {'email': email, 'otp': otp, 'deviceId': deviceId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required String deviceId,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'identifier': identifier,
        'password': password,
        'deviceId': deviceId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    required String deviceId,
  }) async {
    final response = await _dio.post(
      '/auth/google',
      data: {
        'idToken': idToken,
        'deviceId': deviceId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final response = await _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post(
      '/auth/verify-forgot-password',
      data: {'email': email, 'otp': otp},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      '/auth/reset-password',
      data: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String deviceId,
  }) async {
    final response = await _dio.patch(
      '/auth/change-password',
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'deviceId': deviceId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? avatarUrl,
    String? filePath,
  }) async {
    final Map<String, dynamic> map = {};
    if (fullName != null) map['fullName'] = fullName;
    if (phone != null) map['phone'] = phone;
    if (address != null) map['address'] = address;
    if (avatarUrl != null) map['avatarUrl'] = avatarUrl;

    if (filePath != null && filePath.isNotEmpty) {
      map['file'] = await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      );
    }

    final formData = FormData.fromMap(map);

    final response = await _dio.patch(
      '/users/update-profile',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await _dio.post('/auth/logout');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
    required String userId,
    required String deviceId,
  }) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
        'userId': userId,
        'deviceId': deviceId,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
