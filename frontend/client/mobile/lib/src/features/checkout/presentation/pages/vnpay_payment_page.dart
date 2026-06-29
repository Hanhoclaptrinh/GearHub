import 'dart:convert';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mobile/src/core/constants/api_constant.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/profile/presentation/pages/payment_methods_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VnpayPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final PaymentCard? selectedCard;

  const VnpayPaymentPage({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    this.selectedCard,
  });

  @override
  State<VnpayPaymentPage> createState() => _VnpayPaymentPageState();
}

class _VnpayPaymentPageState extends State<VnpayPaymentPage> {
  bool _isLoading = true;
  bool _isProcessingReturn = false;
  InAppWebViewController? _webViewController;
  List<PaymentCard> _savedCards = [];
  PaymentCard? _selectedCard;
  bool _isLoadingCards = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final jsonStr = prefs.getString('saved_payment_cards');
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final cards = decoded
            .map((item) => PaymentCard.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _savedCards = cards;
          if (widget.selectedCard != null) {
            _selectedCard = cards.firstWhere(
              (c) => c.id == widget.selectedCard!.id,
              orElse: () => widget.selectedCard!,
            );
          } else {
            _selectedCard = null;
          }
        });
      }
    } catch (e) {
      debugPrint('[VNPAY Page] Error loading saved cards: $e');
    } finally {
      setState(() => _isLoadingCards = false);
    }
  }

  Future<void> _autoFillCard(PaymentCard card) async {
    if (_webViewController == null) return;

    final number = card.cardNumber;
    final holder = card.cardHolder.toUpperCase();
    final expiry = card.expiryDate;
    final bankName = card.bankName;

    final jsCode = """
      (function() {
        window.vnpayTargetBank = '$bankName';
        window.vnpayTargetNumber = '$number';
        window.vnpayTargetHolder = '$holder';
        window.vnpayTargetExpiry = '$expiry';
        
        window.vnpayCardSubmitted = false;
        window.vnpayOtpSubmitted = false;
        
        function simulateClick(element) {
          if (!element) return;
          element.click();
          const mouseEvents = ['mousedown', 'mouseup', 'click'];
          mouseEvents.forEach(eventType => {
            const event = new MouseEvent(eventType, {
              view: window,
              bubbles: true,
              cancelable: true
            });
            element.dispatchEvent(event);
          });
          if (window.TouchEvent) {
            const touchStart = new TouchEvent('touchstart', { bubbles: true, cancelable: true });
            const touchEnd = new TouchEvent('touchend', { bubbles: true, cancelable: true });
            element.dispatchEvent(touchStart);
            element.dispatchEvent(touchEnd);
          }
        }

        function runAutomator() {
          const bankName = window.vnpayTargetBank;
          const cardNumber = window.vnpayTargetNumber;
          const cardHolder = window.vnpayTargetHolder;
          const expiryDate = window.vnpayTargetExpiry;
          
          if (!cardNumber) return;

          // 1. Check if we are on the Card Input Page or OTP Page
          const inputs = document.querySelectorAll('input');
          let hasCardInputs = false;
          let cardNumberField = null;
          let cardHolderField = null;
          let cardDateField = null;
          let otpField = null;

          for (let input of inputs) {
            const id = (input.id || '').toLowerCase();
            const name = (input.name || '').toLowerCase();
            const placeholder = (input.placeholder || '').toLowerCase();
            
            // OTP field
            if (id.includes('otp') || name.includes('otp') || placeholder.includes('otp') || placeholder.includes('mã xác thực') || placeholder.includes('nhập mã')) {
              if (input.value !== '123456') {
                input.value = '123456';
                input.dispatchEvent(new Event('input', { bubbles: true }));
                input.dispatchEvent(new Event('change', { bubbles: true }));
              }
              otpField = input;
              continue;
            }

            // Card Number
            if (id.includes('number') || name.includes('number') || id.includes('cardnum') || name.includes('cardnum') || placeholder.includes('số thẻ') || placeholder.includes('card number')) {
              if (input.value !== cardNumber) {
                input.value = cardNumber;
                input.dispatchEvent(new Event('input', { bubbles: true }));
                input.dispatchEvent(new Event('change', { bubbles: true }));
              }
              cardNumberField = input;
              hasCardInputs = true;
              continue;
            }
            // Card Holder
            if (id.includes('holder') || name.includes('holder') || id.includes('name') || name.includes('name') || placeholder.includes('tên chủ thẻ') || placeholder.includes('card holder')) {
              if (input.value !== cardHolder) {
                input.value = cardHolder;
                input.dispatchEvent(new Event('input', { bubbles: true }));
                input.dispatchEvent(new Event('change', { bubbles: true }));
              }
              cardHolderField = input;
              continue;
            }
            // Card Date
            if (id.includes('date') || name.includes('date') || id.includes('time') || name.includes('time') || placeholder.includes('ngày') || placeholder.includes('tháng') || placeholder.includes('yy') || placeholder.includes('mm') || placeholder.includes('hạn')) {
              if (input.value !== expiryDate) {
                input.value = expiryDate;
                input.dispatchEvent(new Event('input', { bubbles: true }));
                input.dispatchEvent(new Event('change', { bubbles: true }));
              }
              cardDateField = input;
              continue;
            }
            // Split Month/Year inputs
            if (placeholder.includes('tháng') || placeholder === 'mm' || id.includes('month') || name.includes('month')) {
              const parts = expiryDate.split('/');
              if (parts.length > 0) {
                if (input.value !== parts[0]) {
                  input.value = parts[0];
                  input.dispatchEvent(new Event('input', { bubbles: true }));
                  input.dispatchEvent(new Event('change', { bubbles: true }));
                }
                cardDateField = input;
              }
              continue;
            }
            if (placeholder.includes('năm') || placeholder === 'yy' || id.includes('year') || name.includes('year')) {
              const parts = expiryDate.split('/');
              if (parts.length > 1) {
                if (input.value !== parts[1]) {
                  input.value = parts[1];
                  input.dispatchEvent(new Event('input', { bubbles: true }));
                  input.dispatchEvent(new Event('change', { bubbles: true }));
                }
                cardDateField = input;
              }
              continue;
            }
          }

          // Auto-submit Card Form if filled
          if (cardNumberField && cardHolderField && cardDateField && !window.vnpayCardSubmitted) {
            let submitBtn = document.getElementById('btnPay') || 
                            document.querySelector('button[type="submit"]') ||
                            document.querySelector('input[type="submit"]');
            
            if (!submitBtn) {
              const buttons = document.querySelectorAll('button, input[type="button"], a.btn');
              for (let btn of buttons) {
                const text = (btn.textContent || btn.value || '').toLowerCase();
                if (text.includes('thanh toán') || text.includes('tiếp tục') || text.includes('xác nhận') || text.includes('pay') || text.includes('submit')) {
                  submitBtn = btn;
                  break;
                }
              }
            }
            
            if (submitBtn) {
              window.vnpayCardSubmitted = true;
              setTimeout(function() {
                simulateClick(submitBtn);
              }, 400);
              return;
            }
          }

          // Auto-submit OTP Form if filled
          if (otpField && !window.vnpayOtpSubmitted) {
            let submitBtn = document.getElementById('btnConfirm') || 
                            document.getElementById('btnPay') || 
                            document.querySelector('button[type="submit"]');
            
            if (!submitBtn) {
              const buttons = document.querySelectorAll('button, input[type="button"], a.btn');
              for (let btn of buttons) {
                const text = (btn.textContent || btn.value || '').toLowerCase();
                if (text.includes('xác nhận') || text.includes('confirm') || text.includes('đồng ý') || text.includes('tiếp tục') || text.includes('ok')) {
                  submitBtn = btn;
                  break;
                }
              }
            }
            
            if (submitBtn) {
              window.vnpayOtpSubmitted = true;
              setTimeout(function() {
                simulateClick(submitBtn);
              }, 400);
              return;
            }
          }

          if (hasCardInputs || otpField) return;

          // 2. Check if we are on the Method Selection Page
          const elements = document.querySelectorAll('div, a, p, span, li, h5, h4');
          for (let el of elements) {
            const text = (el.textContent || '').toLowerCase().normalize('NFC').trim();
            if (text.includes('thẻ nội địa') || text.includes('local card') || text.includes('domestic card')) {
              const clickTarget = el.closest('a, button, li, [class*="item"], [class*="method"], [class*="card"]') || el;
              simulateClick(clickTarget);
              return;
            }
          }

          // 3. Check if we are on the Bank List Page
          const bankElements = document.querySelectorAll('div, a, p, span, li, img');
          for (let el of bankElements) {
            const text = (el.textContent || '').toUpperCase().normalize('NFC').trim();
            const alt = (el.alt || '').toUpperCase().normalize('NFC').trim();
            const src = (el.src || '').toLowerCase();
            const id = (el.id || '').toUpperCase();
            
            if (text === bankName.toUpperCase() || 
                text.includes('NGÂN HÀNG ' + bankName.toUpperCase()) ||
                alt === bankName.toUpperCase() || 
                id === bankName.toUpperCase() ||
                (src.includes('/' + bankName.toLowerCase() + '.') || src.includes('_' + bankName.toLowerCase() + '.'))) {
              
              const clickTarget = el.closest('a, button, li, [class*="item"], [class*="bank"]') || el;
              simulateClick(clickTarget);
              return;
            }
          }
        }

        runAutomator();
        if (!window.vnpayAutomatorInterval) {
          window.vnpayAutomatorInterval = setInterval(runAutomator, 500);
        }
      })();
    """;

    try {
      await _webViewController?.evaluateJavascript(source: jsCode);
    } catch (e) {
      debugPrint('[VNPAY Page] JS autofill error: $e');
    }
  }

  void _autoFillDemoNCB() {
    final demoCard = PaymentCard(
      id: 'demo',
      cardNumber: '9704198526191432198',
      cardHolder: 'NGUYEN VAN A',
      expiryDate: '07/15',
      bankName: 'NCB',
    );
    HapticFeedback.lightImpact();
    _autoFillCard(demoCard);
  }

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
        actions: [
          IconButton(
            icon: Icon(Icons.bolt, color: cs.primary),
            onPressed: () {
              if (_selectedCard != null) {
                _autoFillCard(_selectedCard!);
              } else {
                _autoFillDemoNCB();
              }
            },
            tooltip: 'Điền nhanh thông tin thẻ',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.paymentUrl)),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      if (_selectedCard != null) {
                        _autoFillCard(_selectedCard!);
                      }
                    }
                  },
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
                      } else {
                        // Tự động điền nếu có thẻ được chọn
                        if (_selectedCard != null) {
                          Future.delayed(const Duration(milliseconds: 600), () {
                            if (mounted) _autoFillCard(_selectedCard!);
                          });
                        }
                      }
                    }
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
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
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
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
          ),
          _buildPaymentBar(),
        ],
      ),
    );
  }

  Widget _buildPaymentBar() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoadingCards) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.8)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      );
    }

    if (_savedCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.8)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.creditCard,
                    size: 16,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chưa lưu phương thức thanh toán.',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _autoFillDemoNCB,
                icon: const Icon(LucideIcons.bolt, size: 12),
                label: const Text(
                  'Điền thẻ Demo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: cs.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CHỌN THẺ THANH TOÁN NHANH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Chạm để điền',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: cs.secondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 76,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _savedCards.length,
                itemBuilder: (context, index) {
                  final card = _savedCards[index];
                  final isSelected = _selectedCard?.id == card.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedCard = card;
                      });
                      _autoFillCard(card);
                    },
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 12, bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.04)
                            : (isDark ? theme.cardColor : cs.surface),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? cs.primary : cs.outlineVariant,
                          width: isSelected ? 1.4 : 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                card.bankName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                card.expiryDate,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '•••• ${card.cardNumber.substring(card.cardNumber.length - 4)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  card.cardHolder.split(' ').last,
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
        backgroundColor: theme.cardColor,
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
