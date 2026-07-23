import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
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
    if (ApiConstants.baseUrl.contains('10.11.6.48')) {
      // print('🌐 REQUEST[${options.method}] ${options.uri}');
      // if (options.data != null) print('   Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (ApiConstants.baseUrl.contains('10.11.6.48')) {
      // print('✅ RESPONSE[${response.statusCode}] ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (ApiConstants.baseUrl.contains('10.11.6.48')) {
      // print('❌ ERROR[${err.response?.statusCode}] ${err.requestOptions.uri}: ${err.message}');
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
      // print('🔄 Retry ${retryCount + 1}/$maxRetries after ${delay.inSeconds}s');
      Future.delayed(delay, () async {
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        try {
          final dio = Dio();
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