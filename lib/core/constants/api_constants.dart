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
  /// devuelven HTTP 400 (`El tamaño de página no puede ser mayor que 200.`).
  ///
  /// Bajó de 200 a 50 porque las personas ahora incluyen foto. Con 200 la
  /// respuesta pasa de cientos de KB a varios MB, el backend tarda en armarla
  /// y la petición moría por timeout. 50 mantiene el payload por debajo del
  /// límite de tiempo a costa de más viajes.
  static const int defaultPageSize = 50;

  /// Páginas descargadas en paralelo tras la primera. 6 mantiene el servidor
  /// holgado; el _RetryInterceptor puede multiplicar la carga ante un 5xx.
  static const int personasSyncConcurrency = 6;

  /// El endpoint de personas tarda por el peso de las fotos: 20s ya no
  /// alcanzan y la sincronización moría siempre en el primer request.
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 90);
  static const Duration sendTimeout = Duration(seconds: 30);
}