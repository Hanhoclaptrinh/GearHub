import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mobile/src/core/constants/api_constant.dart';
import 'package:url_launcher/url_launcher.dart';

class VnpayPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const VnpayPaymentPage({
    super.key,
    required this.paymentUrl,
    required this.orderId,
  });

  @override
  State<VnpayPaymentPage> createState() => _VnpayPaymentPageState();
}

class _VnpayPaymentPageState extends State<VnpayPaymentPage> {
  bool _isLoading = true;
  bool _isProcessingReturn = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'THANH TOÁN VNPAY',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: cs.onSurface,
            letterSpacing: 1,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
          onPressed: () => _cancelPayment(),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.paymentUrl)),
            onLoadStart: (controller, url) {
              setState(() => _isLoading = true);
              if (url != null) {
                final urlStr = url.toString();
                if (urlStr.contains('/payment/vnpay_return')) {
                  _handleDirectBackendCall(urlStr);
                }
              }
            },
            onLoadStop: (controller, url) async {
              setState(() => _isLoading = false);
              if (url != null) {
                final urlStr = url.toString();
                if (urlStr.contains('/payment/vnpay_return')) {
                  _handleDirectBackendCall(urlStr);
                }
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url!;
              final urlStr = uri.toString();

              if (urlStr.contains('/payment/vnpay_return')) {
                _handleDirectBackendCall(urlStr);
                return NavigationActionPolicy.CANCEL;
              }

              if (![
                'http',
                'https',
                'file',
                'chrome',
                'data',
                'javascript',
                'about',
              ].contains(uri.scheme)) {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: cs.primary,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDirectBackendCall(String urlStr) async {
    if (_isProcessingReturn) return;
    _isProcessingReturn = true;

    try {
      final uri = Uri.parse(urlStr);
      final cleanBase = ApiConstant.baseUrl;
      final backendUrl = '$cleanBase/payment/vnpay_return?${uri.query}';

      final dio = dio_pkg.Dio();
      final response = await dio.get(
        backendUrl,
        options: dio_pkg.Options(
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 302 || response.statusCode == 200) {
        final redirectUrl = response.headers.value('location');
        if (redirectUrl != null && redirectUrl.contains('status=success')) {
          Navigator.of(context).pop(true);
          return;
        }
      }
      //fallback giao dịch thất bại
      Navigator.of(context).pop(false);
    } catch (e) {
      Navigator.of(context).pop(false);
    }
  }

  void _cancelPayment() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
        title: Text(
          'Hủy thanh toán',
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy thanh toán không?',
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Không',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pop(false);
            },
            child: Text(
              'Có, Hủy',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
