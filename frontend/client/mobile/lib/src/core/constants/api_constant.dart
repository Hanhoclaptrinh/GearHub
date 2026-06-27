class ApiConstant {
  ApiConstant._();

  //lấy url từ cấu hình build
  //fallback về giá trị mặc định
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
