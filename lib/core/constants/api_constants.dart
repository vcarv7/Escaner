class ApiConstants {
  static const String baseUrl = 'http://10.11.6.48:7000/';
  static const String authLogin = '/api/v1/auth/token/';
  static const String authRefresh = '/api/v1/auth/token/refresh/';
  static const String authVerify = '/api/v1/auth/token/verify/';
  static const String personas = '/api/v1/base/personas/';

  /// Registros por página solicitados al sincronizar personas.
  /// El backend debe permitir al menos este valor (PersonaPagination.max_page_size),
  /// de lo contrario DRF lo topa en silencio y solo baja PAGE_SIZE registros.
  static const int defaultPageSize = 1000;

  /// Páginas descargadas en paralelo tras la primera. 6 mantiene el servidor
  /// holgado; el _RetryInterceptor puede multiplicar la carga ante un 5xx.
  static const int personasSyncConcurrency = 6;
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}