class ApiConstants {
  /// Backend de preview.
  ///
  /// El nombre de dominio se usa para el certificado: la CA corporativa solo
  /// puede avalar `alimentacion-preview.din.uci.cu`. La IP
  /// (`10.11.2.55`) se aplica aparte, en `tls_trust_io.dart`, porque el DNS de
  /// la red corporativa no resuelve los hosts internos.
  static const String baseUrl = 'https://alimentacion-preview.din.uci.cu/';

  /// IP del backend de preview. La resuelve `setPlatformAddress` al arrancar.
  static const String previewAddress = '10.11.2.55';
  static const String authLogin = '/api/v1/auth/token/';
  static const String authRefresh = '/api/v1/auth/token/refresh/';
  static const String authVerify = '/api/v1/auth/token/verify/';
  static const String personas = '/api/v1/base/personas/';

  /// Registros por página solicitados al descargar personas.
  ///
  /// El backend la valida con un tope propio: peticiones con `page_size > 200`
  /// devuelven HTTP 400 (`El tamaño de página no puede ser mayor que 200.`),
  /// no un tope silencioso. Por eso no se piden 1000 aquí.
  static const int defaultPageSize = 200;

  /// Páginas descargadas en paralelo tras la primera. 6 mantiene el servidor
  /// holgado; el _RetryInterceptor puede multiplicar la carga ante un 5xx.
  static const int personasSyncConcurrency = 6;
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}