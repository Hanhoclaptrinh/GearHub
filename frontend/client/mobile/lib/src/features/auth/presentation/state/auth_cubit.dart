import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({required AuthRepository repository})
    : _repository = repository,
      super(const AuthInitial());

  Future<void> checkAuthStatus() async {
    try {
      final loggedIn = await _repository.isLoggedIn();
      if (loggedIn) {
        final user = await _repository.getMe();
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> requestRegister({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String deviceId,
  }) async {
    emit(const AuthLoading());
    try {
      final message = await _repository.requestRegister(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        deviceId: deviceId,
      );
      emit(AuthRegisterOtpSent(message: message, email: email));
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> verifyRegister({
    required String email,
    required String otp,
    required String deviceId,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _repository.verifyRegister(
        email: email,
        otp: otp,
        deviceId: deviceId,
      );
      emit(AuthAuthenticated(user: result.user));
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
    required String deviceId,
  }) async {
    // phat lenh toi state loading
    emit(const AuthLoading());
    try {
      // dua thong tin login qua repo de xu ly login
      final result = await _repository.login(
        identifier: identifier,
        password: password,
        deviceId: deviceId,
      );
      // phat lenh toi state authenticated
      emit(AuthAuthenticated(user: result.user));
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> forgotPassword({required String email}) async {
    emit(const AuthLoading());
    try {
      final message = await _repository.forgotPassword(email: email);
      emit(AuthForgotPasswordOtpSent(message: message, email: email));
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    emit(const AuthLoading());
    try {
      await _repository.verifyForgotPasswordOtp(email: email, otp: otp);
      emit(AuthForgotPasswordOtpVerified(email: email, otp: otp));
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    emit(const AuthLoading());
    try {
      final message = await _repository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      emit(AuthPasswordResetSuccess(message: message));
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await _repository.logout();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        emit(const AuthUnauthenticated());
        return;
      }
      emit(AuthError(message: _extractError(e)));
      return;
    }
    emit(const AuthUnauthenticated());
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Đã xảy ra lỗi, vui lòng thử lại';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối quá thời gian, vui lòng thử lại';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến máy chủ';
      }
    }
    return 'Đã xảy ra lỗi không xác định';
  }
}
