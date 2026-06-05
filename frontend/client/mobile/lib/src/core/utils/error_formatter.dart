import 'package:dio/dio.dart';

class ErrorFormatter {
  static String format(dynamic e, [String defaultMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại sau!']) {
    if (e is DioException) {
      if (e.response?.statusCode == 429) {
        return 'Bạn đang thao tác quá nhanh. Vui lòng chờ vài giây rồi thử lại!';
      }
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Kết nối mạng quá hạn. Vui lòng kiểm tra lại đường truyền internet!';
        case DioExceptionType.connectionError:
          return 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng của bạn!';
        case DioExceptionType.badResponse:
          final data = e.response?.data;
          if (data is Map) {
            final msg = data['message'];
            if (msg is List) {
              return msg.join('\n');
            }
            if (msg != null) {
              final msgStr = msg.toString();
              if (msgStr.contains('ThrottlerException') || msgStr.toLowerCase().contains('too many requests')) {
                return 'Bạn đang thao tác quá nhanh. Vui lòng chờ vài giây rồi thử lại!';
              }
              return msgStr;
            }
          }
          return 'Máy chủ phản hồi lỗi (${e.response?.statusCode}).';
        default:
          return defaultMessage;
      }
    }
    
    final errStr = e.toString();
    if (errStr.contains('429') || errStr.contains('ThrottlerException') || errStr.toLowerCase().contains('too many requests')) {
      return 'Bạn đang thao tác quá nhanh. Vui lòng chờ vài giây rồi thử lại!';
    }
    
    return defaultMessage;
  }
}
