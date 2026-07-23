class ApiConstants {
  static const String baseUrl = 'http://10.11.6.48:7000/';
  static const String authLogin = '/api/v1/auth/token';
  static const String authRefresh = '/api/v1/auth/token/refresh';
  static const String authVerify = '/api/v1/auth/token/verify';
  static const String personas = '/api/v1/personas';
  static const int defaultPageSize = 100;
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}