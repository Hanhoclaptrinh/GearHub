import 'package:intl/intl.dart';

final _vndFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

String formatVND(double price) {
  return _vndFormatter.format(price);
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
