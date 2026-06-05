import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

class InvoicePage extends StatefulWidget {
  final dynamic order;

  const InvoicePage({super.key, required this.order});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  bool _isDownloading = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _captureAndShare() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 50),
      );

      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/hoa_don_${widget.order['id']}.png',
        ).create();
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Hóa đơn điện tử GearHub đơn hàng #${widget.order['id']}');
      } else {
        throw Exception('Không thể chụp hình ảnh hóa đơn');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi xuất hóa đơn: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final String orderId = order['id'] ?? '';
    final String shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();
    final String receiverName = order['receiverName'] ?? 'Khách hàng GearHub';
    final String receiverPhone = order['receiverPhone'] ?? '';
    final String shippingAddress = order['shippingAddress'] ?? '';
    final String createdAt = order['createdAt'] != null
        ? DateTime.parse(
            order['createdAt'],
          ).toLocal().toString().substring(0, 16)
        : '';

    final List<dynamic> items = order['items'] ?? [];
    double subtotal = _toDouble(order['subtotal']);
    if (subtotal == 0.0) {
      subtotal = items.fold(0.0, (sum, i) {
        final price = _toDouble(i['priceAtPurchase'] ?? i['price']);
        final qty = (i['quantity'] as num?)?.toInt() ?? 1;
        return sum + (price * qty);
      });
    }
    final double shipping = _toDouble(order['shippingFee'] ?? 0.0);
    final double discount = _toDouble(order['discount']);
    double totalAmount = _toDouble(order['totalAmount'] ?? order['total']);
    if (totalAmount == 0.0) {
      totalAmount = subtotal + shipping - discount;
    }

    // tách thuế VAT 8%
    final double priceBeforeVat = subtotal / 1.08;
    final double vatAmount = subtotal - priceBeforeVat;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            'Hóa đơn điện tử',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'CÔNG TY TNHH THƯƠNG MẠI GEARHUB',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Địa chỉ: Tòa nhà GearHub, P. Sài Gòn, TP.Hồ Chí Minh',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                              height: 1.3,
                                            ),
                                          ),
                                          Text(
                                            'Điện thoại: 1800 6789 | Email: contact@gearhub.com',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.bolt,
                                        color: Color(0xFF6366F1),
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildDashedLine(),
                                const SizedBox(height: 16),
                                const Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'HÓA ĐƠN GIÁ TRỊ GIA TĂNG',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF1E293B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '(HÓA ĐƠN ĐIỆN TỬ)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // thông tin chung hóa đơn
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ký hiệu: GH/2026E',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Số hóa đơn: #$shortId',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ngày lập: $createdAt',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            color: const Color(0xFFF8FAFC),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'THÔNG TIN NGƯỜI MUA HÀNG',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildBuyerInfoRow('Họ và tên:', receiverName),
                                _buildBuyerInfoRow(
                                  'Số điện thoại:',
                                  receiverPhone,
                                ),
                                _buildBuyerInfoRow(
                                  'Địa chỉ giao hàng:',
                                  shippingAddress,
                                ),
                              ],
                            ),
                          ),

                          // bảng danh sách sản phẩm
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHI TIẾT SẢN PHẨM',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // header
                                const Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Tên sản phẩm',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'SL',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Thành tiền',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 16,
                                  color: Color(0xFFE2E8F0),
                                ),
                                // table items
                                ...items.map((i) {
                                  final String name =
                                      i['productVariant']?['product']?['name'] ??
                                      'Sản phẩm GearHub';
                                  final int qty =
                                      (i['quantity'] as num?)?.toInt() ?? 1;
                                  final double price = _toDouble(
                                    i['priceAtPurchase'] ?? i['price'],
                                  );
                                  final double amount = price * qty;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF334155),
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'x$qty',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            formatVND(amount),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(
                                  height: 24,
                                  color: Color(0xFFE2E8F0),
                                ),

                                // tổng cộng chi tiết
                                _buildAmountRow(
                                  'Tạm tính:',
                                  formatVND(priceBeforeVat),
                                ),
                                _buildAmountRow(
                                  'Thuế suất GTGT (8%):',
                                  formatVND(vatAmount),
                                ),
                                _buildAmountRow(
                                  'Thành tiền:',
                                  formatVND(subtotal),
                                  isBold: true,
                                ),
                                _buildAmountRow(
                                  'Phí vận chuyển:',
                                  formatVND(shipping),
                                ),
                                if (discount > 0)
                                  _buildAmountRow(
                                    'Mã giảm giá:',
                                    '-${formatVND(discount)}',
                                    valueColor: const Color(0xFF10B981),
                                  ),

                                const Divider(
                                  height: 24,
                                  color: Color(0xFFCBD5E1),
                                  thickness: 1.5,
                                ),

                                // tổng thanh toán
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tổng cộng:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      formatVND(totalAmount),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // chữ ký số
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    border: Border.all(
                                      color: const Color(0xFFA7F3D0),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF059669),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'ĐÃ KÝ SỐ ĐIỆN TỬ',
                                              style: TextStyle(
                                                color: Color(0xFF065F46),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Ký bởi: Công ty TNHH Thương mại GearHub',
                                              style: TextStyle(
                                                color: Color(0xFF047857),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Thời gian ký: $createdAt',
                                              style: const TextStyle(
                                                color: Color(0xFF047857),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.borderCardStrong,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isDownloading ? null : _captureAndShare,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Chia sẻ',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandIndigo,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isDownloading ? null : _captureAndShare,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isDownloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download_rounded, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Tải hóa đơn',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(
        150 ~/ 4,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBuyerInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Chưa cập nhật',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? const Color(0xFF334155) : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
              color:
                  valueColor ??
                  (isBold ? const Color(0xFF334155) : const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
