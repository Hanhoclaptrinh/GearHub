import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ErrorIllustrationWidget extends StatelessWidget {
  final int? statusCode;
  final String? message;
  final String? title;
  final VoidCallback? onRetry;
  final String? customIllustration;

  const ErrorIllustrationWidget({
    super.key,
    this.statusCode,
    this.message,
    this.title,
    this.onRetry,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    //xử lý lỗi dựa trên mã lỗi hoặc nội dung lỗi
    final errorDetails = _resolveErrorDetails();
    final illustrationPath = customIllustration ?? errorDetails.illustration;
    final displayTitle = title ?? errorDetails.title;
    final displayMessage =
        message != null && message!.isNotEmpty && !_isRawSystemError(message!)
        ? message!
        : errorDetails.message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //illustration
            SvgPicture.asset(
              illustrationPath,
              height: 200,
              placeholderBuilder: (BuildContext context) => const SizedBox(
                height: 200,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            //title lỗi
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            //msg des
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Text(
                    'THỬ LẠI',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  //các lỗi raw chưa được chuẩn hóa
  bool _isRawSystemError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('dioexception') ||
        lower.contains('exception') ||
        lower.contains('socketexception') ||
        lower.contains('handshake') ||
        lower.contains('unauthorized') ||
        lower.contains('forbidden') ||
        lower.contains('bad request') ||
        lower.contains('internal server error') ||
        lower.contains('error');
  }

  _ErrorDetails _resolveErrorDetails() {
    int? code = statusCode;

    //xác định mã lỗi dựa trên nội dung lỗi raw
    if (code == null && message != null && message!.isNotEmpty) {
      final msgLower = message!.toLowerCase();
      if (msgLower.contains('401') || msgLower.contains('unauthorized')) {
        code = 401;
      } else if (msgLower.contains('403') || msgLower.contains('forbidden')) {
        code = 403;
      } else if (msgLower.contains('404') || msgLower.contains('not found')) {
        code = 404;
      } else if (msgLower.contains('400') || msgLower.contains('bad request')) {
        code = 400;
      } else if (msgLower.contains('429') ||
          msgLower.contains('too many request') ||
          msgLower.contains('many req')) {
        code = 429;
      } else if (msgLower.contains('500') ||
          msgLower.contains('internal server')) {
        code = 500;
      } else if (msgLower.contains('504') ||
          msgLower.contains('timeout') ||
          msgLower.contains('time out') ||
          msgLower.contains('connection') ||
          msgLower.contains('socketexception') ||
          msgLower.contains('handshake')) {
        code = 504;
      }
    }

    switch (code) {
      case 400:
        return const _ErrorDetails(
          illustration: 'assets/images/badrequest-illustration.svg',
          title: 'Yêu cầu không thể xử lý',
          message:
              'Hệ thống không nhận diện được thao tác này. Bạn vui lòng thử lại nhé.',
        );
      case 401:
        return const _ErrorDetails(
          illustration: 'assets/images/unauthorized-illustration.svg',
          title: 'Phiên đăng nhập hết hạn',
          message:
              'Bạn vui lòng đăng nhập lại để tiếp tục mua sắm và nhận các đặc quyền thành viên.',
        );
      case 403:
        return const _ErrorDetails(
          illustration: 'assets/images/forbidden-illustration.svg',
          title: 'Giới hạn quyền truy cập',
          message:
              'Tài khoản của bạn hiện chưa có quyền thực hiện thao tác hoặc truy cập nội dung này.',
        );
      case 404:
        return const _ErrorDetails(
          illustration: 'assets/images/notfound-illustration.svg',
          title: 'Không tìm thấy trang',
          message:
              'Nội dung hoặc sản phẩm bạn đang tìm kiếm không tồn tại hoặc đã bị dời đi.',
        );
      case 429:
        return const _ErrorDetails(
          illustration: 'assets/images/toomanyrequest-illustration.svg',
          title: 'Thao tác quá nhanh',
          message:
              'Hệ thống đang tiếp nhận nhiều yêu cầu cùng lúc. Bạn vui lòng đợi vài giây rồi thử lại nhé.',
        );
      case 500:
        return const _ErrorDetails(
          illustration: 'assets/images/internalservererror-illustration.svg',
          title: 'Hệ thống gặp sự cố nhỏ',
          message:
              'Máy chủ GearHub đang bị gián đoạn. Tụi mình đang khẩn trương khắc phục, bạn quay lại sau xíu nhé.',
        );
      case 504:
        return const _ErrorDetails(
          illustration: 'assets/images/gatewaytimeout-illustration.svg',
          title: 'Kết nối mạng không ổn định',
          message:
              'Không nhận được phản hồi từ máy chủ. Bạn vui lòng kiểm tra lại kết nối Wi-Fi hoặc 4G nhé.',
        );
      default:
        return const _ErrorDetails(
          illustration: 'assets/images/badrequest-illustration.svg',
          title: 'Đã xảy ra sự cố',
          message:
              'Không thể kết nối đến máy chủ. Bạn vui lòng kiểm tra lại mạng hoặc khởi động lại ứng dụng.',
        );
    }
  }
}

class _ErrorDetails {
  final String illustration;
  final String title;
  final String message;

  const _ErrorDetails({
    required this.illustration,
    required this.title,
    required this.message,
  });
}
