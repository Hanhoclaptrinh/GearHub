import 'package:intl/intl.dart';

final _vndFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

String formatVND(double price) {
  return _vndFormatter.format(price);
}
