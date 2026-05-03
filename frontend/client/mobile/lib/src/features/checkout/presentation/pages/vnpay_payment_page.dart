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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'THANH TOÁN VNPAY',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
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

              if (!['http', 'https', 'file', 'chrome', 'data', 'javascript', 'about'].contains(uri.scheme)) {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
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
      // fallback giao dich that bai
      Navigator.of(context).pop(false);
    } catch (e) {
      Navigator.of(context).pop(false);
    }
  }

  void _cancelPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thanh toán'),
        content: const Text('Bạn có chắc chắn muốn hủy thanh toán không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pop(false);
            },
            child: const Text('Có, Hủy'),
          ),
        ],
      ),
    );
  }
}
