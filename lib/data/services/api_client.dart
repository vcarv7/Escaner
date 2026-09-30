import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_logger.dart' as app_logger;
import '../services/auth_interceptor.dart';
import '../services/auth_token_storage.dart';
import '../services/tls/tls_trust.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // La CA corporativa se registra desde initPlatformTls(). Sin esto el
    // handshake falla con "unable to get local issuer certificate" porque estas
    // peticiones salen por el BoringSSL de Dart, no por el stack de Android.
    // createPlatformAdapter devuelve null en web o si no hay override, y en ese
    // caso queda el adapter por defecto.
    final adapter = createPlatformAdapter(ApiConstants.baseUrl);
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
    }

    _dio.interceptors.addAll([
      AuthInterceptor(AuthTokenStorage(), _dio),
      _LoggingInterceptor(),
      _RetryInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}

class _LoggingInterceptor extends Interceptor {
  _LoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      app_logger.log.logRequest(options.method, options.uri, data: options.data);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      app_logger.log.logResponse(response.statusCode ?? 0, response.requestOptions.uri);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      app_logger.log.logError(err.requestOptions.uri, err);
    }
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  static const int maxRetries = 2;

  _RetryInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (retryCount < maxRetries && _shouldRetry(err)) {
      final delay = Duration(seconds: 1 << retryCount);
      Future.delayed(delay, () async {
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        try {
          final dio = ApiClient().dio;
          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);
        } catch (e) {
          handler.next(err);
        }
      });
      return;
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}