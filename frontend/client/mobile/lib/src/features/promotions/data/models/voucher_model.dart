import 'package:mobile/src/core/utils/formatter_utils.dart';

class VoucherModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String type;
  final double value;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final int quantity;
  final int claimedCount;
  final int usedCount;
  final String? startsAt;
  final String? expiresAt;
  final bool isActive;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.type,
    required this.value,
    required this.minOrderAmount,
    this.maxDiscountAmount,
    required this.quantity,
    required this.claimedCount,
    required this.usedCount,
    this.startsAt,
    this.expiresAt,
    required this.isActive,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'PERCENT',
      value: _toDouble(json['value']),
      minOrderAmount: _toDouble(json['minOrderAmount']),
      maxDiscountAmount: json['maxDiscountAmount'] != null
          ? _toDouble(json['maxDiscountAmount'])
          : null,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      claimedCount: (json['claimedCount'] as num?)?.toInt() ?? 0,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      startsAt: json['startsAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  bool get isPercent => type == 'PERCENT';

  // tạo chuỗi mô tả cho voucher
  String get summaryText {
    if (isPercent) {
      final maxPart = maxDiscountAmount != null && maxDiscountAmount! > 0
          ? ' tối đa ${formatCompact(maxDiscountAmount!)}'
          : '';
      return 'Giảm ${value.toInt()}%$maxPart cho đơn từ ${formatCompact(minOrderAmount)}';
    } else {
      return 'Giảm ${formatCompact(value)} cho đơn từ ${formatCompact(minOrderAmount)}';
    }
  }
}
