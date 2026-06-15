import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

///dịch vụ xác thực bằng google
class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final Logger _logger = Logger();

  GoogleAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  ///xử lý đăng nhập bằng google và trả về firebase id token
  ///nếu user cancel thì trả về null
  Future<String?> signInAndGetIdToken() async {
    try {
      //khởi tạo đăng nhập bằng google
      _logger.d('Starting Google Sign-In...');
      await _googleSignIn.initialize();
      await _googleSignIn.signOut();
      //thực hiện xác thực google
      final dynamic account = await _googleSignIn.authenticate();
      if (account == null) {
        //thao tác bị hủy bởi user
        _logger.w('Google Sign-In was cancelled by user');
        return null;
      }
      _logger.d(
        'Google Sign-In successful for email: ${account.email}, retrieving authentication info...',
      );
      //lấy id token từ google
      final GoogleSignInAuthentication auth = account.authentication;
      final String? googleIdToken = auth.idToken;
      if (googleIdToken == null || googleIdToken.isEmpty) {
        _logger.e('Failed to retrieve Google ID Token');
        throw Exception(
          'Mã xác thực Google (ID Token) không hợp lệ hoặc bị trống',
        );
      }
      //đăng nhập vào firebase bằng credential
      _logger.d('Signing in to Firebase with Google credentials...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleIdToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        _logger.e('Firebase sign-in failed: User is null');
        throw Exception('Đăng nhập Firebase thất bại');
      }
      //lấy firebase id token sau khi đăng nhập thành công
      _logger.d('Retrieving Firebase ID Token...');
      final String? firebaseIdToken = await firebaseUser.getIdToken();

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        _logger.e('Failed to retrieve Firebase ID Token');
        throw Exception('Không lấy được mã xác thực Firebase (ID Token)');
      }

      _logger.d('Successfully retrieved Firebase ID Token');
      return firebaseIdToken;
    } on PlatformException catch (e) {
      //các lỗi khác từ platform
      final isCancel =
          e.code == 'sign_in_cancelled' ||
          e.code == 'canceled' ||
          e.code == 'cancelled' ||
          e.message?.contains('12501') == true ||
          e.toString().contains('12501') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('canceled') ||
          e.toString().toLowerCase().contains('cancel');

      if (isCancel) {
        //bỏ qua lỗi khi user chủ động hủy
        _logger.w('Google Sign-In was cancelled by user');
        return null;
      }
      _logger.e('PlatformException during Google Sign-In: $e');
      rethrow;
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('cancel') ||
          str.contains('canceled') ||
          str.contains('cancelled') ||
          str.contains('12501')) {
        _logger.w('Google Sign-In was cancelled by user (generic catch)');
        return null;
      }
      _logger.e('Error during Google Sign-In & Firebase exchange: $e');
      rethrow;
    }
  }

  ///xử lý đăng xuất google và firebase
  ///xóa token id, fcm-token
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      _logger.d('Google and Firebase accounts signed out successfully');
    } catch (e) {
      _logger.e('Error during Sign-Out: $e');
    }
  }
}
