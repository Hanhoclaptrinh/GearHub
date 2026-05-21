import 'package:intl/intl.dart';

final _vndFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

String formatVND(double price) {
  return _vndFormatter.format(price);
}

String formatCompact(double amount) {
  if (amount >= 1000000) {
    final m = amount / 1000000;
    return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}tr';
  }
  if (amount >= 1000) {
    final k = amount / 1000;
    return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
  }
  return '${amount.toInt()}đ';
}

String formatCompactNumber(int number) {
  if (number >= 1000000000) {
    return '${(number / 1000000000).toStringAsFixed(1).replaceAll('.0', '')}B';
  }
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
  }
  if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
  }
  return number.toString();
}

String formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays == 0) return 'Hôm nay';
  if (difference.inDays == 1) return 'Hôm qua';
  if (difference.inDays < 7) return '${difference.inDays} ngày trước';
  return '${date.day}/${date.month}/${date.year}';
}
