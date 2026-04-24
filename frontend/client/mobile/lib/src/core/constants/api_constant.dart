import 'dart:io';

class ApiConstant {
  ApiConstant._();

  // base url
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.1.5:3000';
    }
    return 'http://localhost:3000';
  }
}
